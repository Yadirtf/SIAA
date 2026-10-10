// Package seed — parámetros globales por defecto del sistema.
package seed

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

// clavesHeredadas son los alias camelCase que sembraban versiones anteriores. No pertenecen
// al catálogo (domain/parametro) y aparecían duplicados en /parametros/efectivos.
var clavesHeredadas = []string{
	"holguraEntradaAntesMin", "holguraEntradaDespuesMin", "umbralTardanzaMin",
	"holguraSalidaAntesMin", "holguraSalidaDespuesMin", "precisionGpsMaxMetros",
	"bufferPerimetralMetros", "marcajeSalidaObligatorio", "marcajeOfflinePermitido",
	"bloquearMockLocation", "bloquearDispositivoRooteado", "promedioLecturasVertice",
	"maxIntentosFallidos", "duracionBloqueoMin", "ventanaIntentosFallidosMin",
}

// seedGlobalParams deja el nivel GLOBAL limpio. Los valores por defecto del SRS §3.5 viven en
// parametro.ValoresPorDefecto() y la cascada los aplica sin necesidad de documentos; aquí solo
// se retiran los documentos camelCase sembrados por versiones anteriores (US-PAR-01 AC-01).
func seedGlobalParams(ctx context.Context, db *mongo.Database) error {
	filtro := bson.M{"ambito": "GLOBAL", "clave": bson.M{"$in": clavesHeredadas}}
	if _, err := db.Collection("parametros").DeleteMany(ctx, filtro); err != nil {
		return fmt.Errorf("retirar parámetros heredados: %w", err)
	}
	return nil
}
