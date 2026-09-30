package impl

import (
	"go.mongodb.org/mongo-driver/bson"

	"github.com/siaa/backend/internal/repository"
)

// condicionAlcance traduce el filtro de alcance a una condición MongoDB sobre documentos
// que guardan sedeId y facultadId. campoUsuario es el campo del dueño del registro.
// Devuelve nil cuando no hay restricción.
func condicionAlcance(f *repository.FiltroAlcance, campoUsuario string) bson.M {
	if f == nil {
		return nil
	}
	if f.UsuarioID != "" {
		return bson.M{campoUsuario: f.UsuarioID}
	}
	var o []bson.M
	if len(f.Sedes) > 0 {
		o = append(o, bson.M{"sedeId": bson.M{"$in": f.Sedes}})
	}
	if len(f.Facultades) > 0 {
		o = append(o, bson.M{"facultadId": bson.M{"$in": f.Facultades}})
	}
	if len(o) == 0 {
		// Rol con ámbito pero sin ámbitos asignados: no ve nada.
		return bson.M{"_id": bson.M{"$exists": false}}
	}
	return bson.M{"$or": o}
}
