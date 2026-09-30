package com.example.siaa_mobile

import android.content.Context
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenProvider
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Canal "siaa/integridad": obtiene tokens de Play Integrity (Standard API) vinculados
 * al requestHash de cada intento de marcaje. El servidor descifra y evalúa el token.
 */
class IntegridadChannel(context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CANAL = "siaa/integridad"
    }

    private val manager: StandardIntegrityManager = IntegrityManagerFactory.createStandard(context)
    private var proveedor: StandardIntegrityTokenProvider? = null
    private var proyectoProveedor: Long? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "solicitarToken") {
            result.notImplemented()
            return
        }
        val proyecto = call.argument<Number>("numeroProyecto")?.toLong()
        val hash = call.argument<String>("requestHash")
        if (proyecto == null || hash.isNullOrEmpty()) {
            result.error("ARGUMENTOS", "numeroProyecto y requestHash son obligatorios", null)
            return
        }
        obtenerProveedor(proyecto, { p -> solicitar(p, hash, result) }, { e ->
            result.error("PREPARAR", e.message, null)
        })
    }

    private fun obtenerProveedor(
        proyecto: Long,
        onListo: (StandardIntegrityTokenProvider) -> Unit,
        onError: (Exception) -> Unit,
    ) {
        val cacheado = proveedor
        if (cacheado != null && proyectoProveedor == proyecto) {
            onListo(cacheado)
            return
        }
        val solicitud = PrepareIntegrityTokenRequest.builder()
            .setCloudProjectNumber(proyecto)
            .build()
        manager.prepareIntegrityToken(solicitud)
            .addOnSuccessListener { p ->
                proveedor = p
                proyectoProveedor = proyecto
                onListo(p)
            }
            .addOnFailureListener { e -> onError(e) }
    }

    private fun solicitar(
        p: StandardIntegrityTokenProvider,
        hash: String,
        result: MethodChannel.Result,
    ) {
        val solicitud = StandardIntegrityTokenRequest.builder()
            .setRequestHash(hash)
            .build()
        p.request(solicitud)
            .addOnSuccessListener { respuesta -> result.success(respuesta.token()) }
            .addOnFailureListener { e ->
                // El proveedor puede invalidarse (p. ej. INTEGRITY_TOKEN_PROVIDER_INVALID):
                // se descarta para prepararlo de nuevo en la próxima solicitud.
                proveedor = null
                proyectoProveedor = null
                result.error("SOLICITAR", e.message, null)
            }
    }
}
