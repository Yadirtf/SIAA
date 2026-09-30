package notificaciones

import (
	"context"
	"fmt"
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/notificacion"
	"github.com/siaa/backend/internal/repository"
)

// zona es la hora institucional en la que se redactan los avisos.
var zona = func() *time.Location {
	if loc, err := time.LoadLocation("America/Bogota"); err == nil {
		return loc
	}
	return time.FixedZone("COT", -5*3600)
}()

// Productor redacta y encola los avisos del catálogo (US-NOT-02 AC-01). El envío es asíncrono:
// lo hace el Despachador en el worker (US-NOT-01 AC-05).
type Productor struct {
	cola       repository.NotificacionRepository
	estructura repository.EstructuraRepository
	espacios   repository.EspacioRepository
}

// NewProductor crea el productor; los repositorios de nombres son opcionales.
func NewProductor(cola repository.NotificacionRepository, estructura repository.EstructuraRepository, espacios repository.EspacioRepository) *Productor {
	return &Productor{cola: cola, estructura: estructura, espacios: espacios}
}

// encolar deja el aviso en la cola; un aviso repetido (misma clave) no es un error.
func (p *Productor) encolar(ctx context.Context, usuarioID string, tipo notificacion.Tipo, titulo, cuerpo, clave string, datos map[string]string, vence *time.Time) error {
	if datos == nil {
		datos = map[string]string{}
	}
	datos["ruta"] = notificacion.RutaDe(tipo)
	_, err := p.cola.Encolar(ctx, &notificacion.Notificacion{
		UsuarioID: usuarioID, Tipo: tipo, Titulo: titulo, Cuerpo: cuerpo, Datos: datos,
		ClaveDedupe: clave, ProgramadaPara: time.Now().UTC(), VenceEn: vence,
	})
	return err
}

// describir arma "Cálculo (A-301) a las 10:00" con los nombres disponibles.
func (p *Productor) describir(ctx context.Context, s *academico.Sesion) string {
	nombre := "tu clase"
	if p.estructura != nil && s.AsignaturaID() != "" {
		if a, err := p.estructura.GetAsignaturaByID(ctx, s.AsignaturaID()); err == nil && a != nil {
			nombre = a.Nombre()
		}
	}
	if p.espacios != nil && s.EspacioID() != "" {
		if e, err := p.espacios.FindByID(ctx, s.EspacioID()); err == nil && e != nil {
			nombre += " (" + e.Codigo + ")"
		}
	}
	return nombre
}

func hora(t time.Time) string { return t.In(zona).Format("15:04") }

// RecordatorioSesion avisa que una clase está por iniciar (RF-NOT-002).
func (p *Productor) RecordatorioSesion(ctx context.Context, s *academico.Sesion, docenteID string) error {
	inicio := s.InicioProgramado()
	cierre := s.VentanaEntradaCierra()
	return p.encolar(ctx, docenteID, notificacion.TipoRecordatorioSesion, "Tu clase inicia pronto",
		fmt.Sprintf("%s inicia a las %s. Recuerda marcar tu entrada desde el aula.", p.describir(ctx, s), hora(inicio)),
		"recordatorio:"+s.ID()+":"+docenteID, map[string]string{"sesionId": s.ID()}, &cierre)
}

// CierreVentana avisa que la ventana de marcaje cierra y aún no hay entrada (US-MAR-12).
func (p *Productor) CierreVentana(ctx context.Context, s *academico.Sesion, docenteID string) error {
	cierre := s.VentanaEntradaCierra()
	return p.encolar(ctx, docenteID, notificacion.TipoCierreVentana, "Tu ventana de marcaje está por cerrar",
		fmt.Sprintf("Aún no registras la entrada de %s. La ventana cierra a las %s.", p.describir(ctx, s), hora(cierre)),
		"cierre:"+s.ID()+":"+docenteID, map[string]string{"sesionId": s.ID()}, &cierre)
}

// ResultadoJustificacion informa la decisión del revisor (RF-JUS-005, RF-NOT-002). Es de mejor
// esfuerzo: la revisión ya quedó registrada y el solicitante también recibe correo.
func (p *Productor) ResultadoJustificacion(ctx context.Context, docenteID, justificacionID, nombreSesion string, aprobada bool) {
	resultado := "rechazada"
	if aprobada {
		resultado = "aprobada"
	}
	_ = p.encolar(ctx, docenteID, notificacion.TipoResultadoJustificacion, "Justificación "+resultado,
		fmt.Sprintf("Tu justificación de %s fue %s.", nombreSesion, resultado),
		"justificacion:"+justificacionID+":"+resultado, map[string]string{"justificacionId": justificacionID}, nil)
}

// CambioSesion informa una cancelación, un cambio de aula o de docente (RF-NOT-002). Es de
// mejor esfuerzo: el cambio ya quedó registrado y el horario de la app lo refleja.
func (p *Productor) CambioSesion(ctx context.Context, s *academico.Sesion, docentes []string, titulo, detalle string) {
	cuerpo := fmt.Sprintf("%s del %s a las %s. %s", p.describir(ctx, s), s.InicioProgramado().In(zona).Format("02/01"), hora(s.InicioProgramado()), detalle)
	marca := time.Now().UTC().Format(time.RFC3339Nano)
	for _, d := range docentes {
		_ = p.encolar(ctx, d, notificacion.TipoCambioHorario, titulo, cuerpo,
			"cambio:"+s.ID()+":"+d+":"+marca, map[string]string{"sesionId": s.ID()}, nil)
	}
}
