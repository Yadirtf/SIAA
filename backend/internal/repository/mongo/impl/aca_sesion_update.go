package impl

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/siaa/backend/internal/domain/academico"
)

// Update guarda los campos que cambian después de generar la sesión: aula, estado, docentes,
// reprogramación y ventana estudiantil (US-ACA-06, US-ACA-09, US-MAR-13).
func (r *sesionRepository) Update(ctx context.Context, s *academico.Sesion) error {
	oid, err := primitive.ObjectIDFromHex(s.ID())
	if err != nil {
		return fmt.Errorf("invalid sesion ID: %w", err)
	}
	update := bson.D{{Key: "$set", Value: bson.D{
		{Key: "espacioId", Value: s.EspacioID()},
		{Key: "estado", Value: string(s.Estado())},
		{Key: "espacioVersionGeometria", Value: s.EspacioVersionGeometria()},
		{Key: "motivoCancelacion", Value: s.MotivoCancelacion()},
		{Key: "ventanaEstudiantil", Value: ventanaEstDeDominio(s.VentanaEstudiantil())},
		{Key: "fecha", Value: s.Fecha()},
		{Key: "horaInicio", Value: s.HoraInicio()},
		{Key: "horaFin", Value: s.HoraFin()},
		{Key: "inicioProgramado", Value: s.InicioProgramado()},
		{Key: "finProgramado", Value: s.FinProgramado()},
		{Key: "ventanaEntradaAbre", Value: s.VentanaEntradaAbre()},
		{Key: "ventanaEntradaCierra", Value: s.VentanaEntradaCierra()},
		{Key: "ventanaSalidaAbre", Value: s.VentanaSalidaAbre()},
		{Key: "ventanaSalidaCierra", Value: s.VentanaSalidaCierra()},
		{Key: "docenteIds", Value: s.DocenteIDs()},
		{Key: "ranuraOriginal", Value: ranuraDeDominio(s.RanuraOriginal())},
		{Key: "actualizadoEn", Value: time.Now().UTC()},
	}}}
	_, err = r.col.UpdateByID(ctx, oid, update)
	return err
}
