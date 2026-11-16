"""Pruebas automáticas de la infraestructura como código.

Leen los archivos de infra/terraform y comprueban que cumplen los requerimientos de seguridad
y monitoreo (docs/REQUISITOS.md) sin necesidad de credenciales de AWS.
"""

from pathlib import Path

import hcl2
import pytest

TF_DIR = Path(__file__).resolve().parents[2] / "infra" / "terraform"


def _load() -> dict[str, dict[str, dict]]:
    """Devuelve {tipo_de_recurso: {nombre: bloque}} con todos los .tf del directorio."""
    recursos: dict[str, dict[str, dict]] = {}
    for archivo in sorted(TF_DIR.glob("*.tf")):
        with archivo.open(encoding="utf-8") as f:
            datos = hcl2.load(f)
        for bloque in datos.get("resource", []):
            for tipo, instancias in bloque.items():
                for nombre, cuerpo in instancias.items():
                    recursos.setdefault(tipo, {})[nombre] = cuerpo
    return recursos


@pytest.fixture(scope="module")
def tf():
    return _load()


def _bloque(valor):
    """hcl2 devuelve los bloques anidados como lista; se toma el primero."""
    return valor[0] if isinstance(valor, list) else valor


# ---------- Seguridad (requisito RS) ----------
def test_base_de_datos_no_se_expone_en_el_security_group(tf):
    sg = tf["aws_security_group"]["app"]
    puertos = {int(r["from_port"]) for r in sg["ingress"]}
    assert 5432 not in puertos
    assert puertos <= {22, 80}


def test_instancia_exige_imdsv2_y_disco_cifrado(tf):
    inst = tf["aws_instance"]["app"]
    assert _bloque(inst["metadata_options"])["http_tokens"] == "required"
    assert _bloque(inst["root_block_device"])["encrypted"] is True


def test_instancia_usa_rol_iam_en_vez_de_claves(tf):
    assert "iam_instance_profile" in tf["aws_instance"]["app"]
    assert "aws_iam_instance_profile" in tf
    assert "aws_iam_access_key" not in tf, "No se deben crear claves de acceso de larga duración"


def test_politicas_iam_no_usan_accion_comodin():
    for archivo in TF_DIR.glob("*.tf"):
        texto = archivo.read_text(encoding="utf-8")
        assert 'actions   = ["*"]' not in texto and 'actions = ["*"]' not in texto, archivo.name
        assert '"Action": "*"' not in texto, archivo.name


def test_no_hay_credenciales_en_el_codigo():
    patrones = ("AKIA", "aws_secret_access_key", "BEGIN PRIVATE KEY", "password =")
    for archivo in TF_DIR.glob("*.tf"):
        texto = archivo.read_text(encoding="utf-8")
        for patron in patrones:
            assert patron not in texto, f"{patron!r} encontrado en {archivo.name}"


# ---------- Trazabilidad (requisito RT) ----------
def test_cloudtrail_activo_con_validacion_de_archivos(tf):
    trail = tf["aws_cloudtrail"]["main"]
    assert trail["enable_log_file_validation"] is True
    assert trail["is_multi_region_trail"] is True
    assert "cloud_watch_logs_group_arn" in trail


def test_bucket_de_cloudtrail_es_privado_y_cifrado(tf):
    acceso = tf["aws_s3_bucket_public_access_block"]["trail"]
    opciones = ("block_public_acls", "block_public_policy", "ignore_public_acls", "restrict_public_buckets")
    for opcion in opciones:
        assert acceso[opcion] is True, opcion
    assert "trail" in tf["aws_s3_bucket_server_side_encryption_configuration"]


# ---------- Monitoreo y logging (requisito RM) ----------
ALARMAS_ESPERADAS = {
    "cpu_alta",
    "estado_instancia",
    "memoria_alta",
    "disco_lleno",
    "errores_app",
    "unauthorized_calls",
}


def test_alarmas_requeridas_existen_y_notifican(tf):
    alarmas = tf["aws_cloudwatch_metric_alarm"]
    assert ALARMAS_ESPERADAS <= set(alarmas)
    for nombre in ALARMAS_ESPERADAS:
        assert alarmas[nombre]["alarm_actions"], f"{nombre} no envía notificaciones"


def test_logs_tienen_retencion_definida(tf):
    for nombre, grupo in tf["aws_cloudwatch_log_group"].items():
        assert "retention_in_days" in grupo, nombre


def test_agente_recolecta_logs_de_contenedores_y_metricas(tf):
    config = tf["aws_ssm_parameter"]["cwagent_config"]["value"]
    assert "-json.log" in config  # logs de Docker
    assert "mem_used_percent" in config and "used_percent" in config


def test_dashboard_define_widgets(tf):
    cuerpo = tf["aws_cloudwatch_dashboard"]["main"]["dashboard_body"]
    assert "widgets" in cuerpo
