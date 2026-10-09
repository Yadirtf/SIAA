package notificaciones

import (
	"context"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/domain/notificacion"
)

// encolarNuevo deja el aviso en la cola e indica si es nuevo (false = ya se había encolado).
func (p *Productor) encolarNuevo(ctx context.Context, usuarioID string, tipo notificacion.Tipo, titulo, cuerpo, clave string, datos map[string]string) (bool, error) {
	if datos == nil {
		datos = map[string]string{}
	}
	datos["ruta"] = notificacion.RutaDe(tipo)
	return p.cola.Encolar(ctx, &notificacion.Notificacion{
		UsuarioID: usuarioID, Tipo: tipo, Titulo: titulo, Cuerpo: cuerpo, Datos: datos,
		ClaveDedupe: clave, ProgramadaPara: time.Now().UTC(),
	})
}

// RecordatorioRevision recuerda al revisor una justificación sin resolver (US-JUS-04 AC-02). La
// clave es la justificación y el revisor: el recordatorio sale una sola vez.
func (p *Productor) RecordatorioRevision(ctx context.Context, revisorID, justificacionID, nombreSesion, fechaSesion string, horas int) (bool, error) {
	que := "una sesión"
	if nombreSesion != "" {
		que = nombreSesion
	}
	if fechaSesion != "" {
		que += " del " + fechaSesion
	}
	return p.encolarNuevo(ctx, revisorID, notificacion.TipoRecordatorioRevision, "Justificación pendiente de revisión",
		fmt.Sprintf("La justificación de %s lleva más de %d horas sin resolver. Revísala para cerrar el caso.", que, horas),
		"revision:"+justificacionID+":"+revisorID, map[string]string{"justificacionId": justificacionID})
}

// VencimientoRol avisa al administrador que el rol de un usuario termina pronto (US-ROL-05 AC-02).
// La clave incluye la fecha de fin: si la vigencia se prorroga, el nuevo vencimiento se avisa otra vez.
func (p *Productor) VencimientoRol(ctx context.Context, adminID, usuarioID, nombreUsuario, rol string, fin time.Time) (bool, error) {
	return p.encolarNuevo(ctx, adminID, notificacion.TipoVencimientoRol, "Rol próximo a vencer",
		fmt.Sprintf("El rol %s de %s vence el %s. Prorróguelo o asigne un reemplazo si el encargo continúa.",
			rol, nombreUsuario, fin.In(zona).Format("02/01/2006 15:04")),
		"vencimiento-rol:"+usuarioID+":"+rol+":"+fin.UTC().Format(time.RFC3339)+":"+adminID,
		map[string]string{"usuarioId": usuarioID, "rol": rol})
}

// SolicitudDerechosRadicada avisa al responsable que tiene un caso nuevo de derechos del titular.
func (p *Productor) SolicitudDerechosRadicada(ctx context.Context, responsableID, solicitudID, tipo string, vence time.Time) {
	_, _ = p.encolarNuevo(ctx, responsableID, notificacion.TipoSolicitudDerechos, "Nueva solicitud de derechos del titular",
		fmt.Sprintf("Se le asignó una solicitud de %s. Plazo legal de respuesta: %s.", tipo, vence.In(zona).Format("02/01/2006")),
		"derechos:"+solicitudID+":responsable:"+responsableID, map[string]string{"solicitudId": solicitudID})
}

// SolicitudDerechosResuelta informa al titular la respuesta a su solicitud (US-LEG-02 AC-02).
func (p *Productor) SolicitudDerechosResuelta(ctx context.Context, titularID, solicitudID, tipo, estado string) {
	_, _ = p.encolarNuevo(ctx, titularID, notificacion.TipoSolicitudDerechos, "Respuesta a su solicitud de datos personales",
		fmt.Sprintf("Su solicitud de %s quedó %s. Consulte la respuesta en Privacidad y datos.", tipo, estado),
		"derechos:"+solicitudID+":resuelta", map[string]string{"solicitudId": solicitudID})
}
