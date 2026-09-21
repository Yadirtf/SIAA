// Package seed — parámetros globales por defecto del sistema.
package seed

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type paramDoc struct {
	Ambito       string      `bson:"ambito"`
	AmbitoID     *string     `bson:"ambitoId"`
	Clave        string      `bson:"clave"`
	Valor        interface{} `bson:"valor"`
	VigenteDesde time.Time   `bson:"vigenteDesde"`
	CreadoEn     time.Time   `bson:"creadoEn"`
}

// seedGlobalParams inserta los parámetros de configuración global (SRS §3.5).
// Los valores solo se insertan si no existe el parámetro ($setOnInsert).
func seedGlobalParams(ctx context.Context, db *mongo.Database) error {
	col := db.Collection("parametros")
	now := time.Now().UTC()

	// Valores por defecto definidos en SRS §3.5
	defaults := []struct {
		clave string
		valor interface{}
	}{
		{"holguraEntradaAntesMin", 15},
		{"holguraEntradaDespuesMin", 15},
		{"umbralTardanzaMin", 10},
		{"holguraSalidaAntesMin", 10},
		{"holguraSalidaDespuesMin", 20},
		{"precisionGpsMaxMetros", 35.0},
		{"bufferPerimetralMetros", 10.0},
		{"marcajeSalidaObligatorio", false},
		{"marcajeOfflinePermitido", true},
		{"bloquearMockLocation", true},
		{"bloquearDispositivoRooteado", false},
		{"promedioLecturasVertice", 5},
		{"maxIntentosFallidos", 5},
		{"duracionBloqueoMin", 15},
		{"ventanaIntentosFallidosMin", 15},
	}

	upsertOpts := options.Update().SetUpsert(true)
	for _, d := range defaults {
		filter := bson.D{
			{Key: "ambito", Value: "GLOBAL"},
			{Key: "ambitoId", Value: nil},
			{Key: "clave", Value: d.clave},
		}
		update := bson.D{{Key: "$setOnInsert", Value: paramDoc{
			Ambito:       "GLOBAL",
			AmbitoID:     nil,
			Clave:        d.clave,
			Valor:        d.valor,
			VigenteDesde: now,
			CreadoEn:     now,
		}}}
		if _, err := col.UpdateOne(ctx, filter, update, upsertOpts); err != nil {
			return fmt.Errorf("upsert param %s: %w", d.clave, err)
		}
	}
	return nil
}
