// Package seed — siembra de roles predefinidos del sistema.
package seed

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"github.com/siaa/backend/internal/domain/rbac"
)

type roleDoc struct {
	ID          primitive.ObjectID `bson:"_id,omitempty"`
	Nombre      string             `bson:"nombre"`
	Descripcion string             `bson:"descripcion"`
	Permisos    []string           `bson:"permisos"`
	Predefinido bool               `bson:"predefinido"` // no puede eliminarse
	CreadoEn    time.Time          `bson:"creadoEn"`
}

// seedRoles inserta los roles predefinidos del sistema con sus permisos (SRS §3.2).
// Usa $setOnInsert para no sobreescribir roles modificados manualmente.
func seedRoles(ctx context.Context, db *mongo.Database) error {
	col := db.Collection("roles")
	now := time.Now().UTC()

	roles := []struct {
		nombre      rbac.RoleName
		descripcion string
	}{
		{rbac.RolSuperadmin, "Superadministrador del sistema con acceso total"},
		{rbac.RolAdminInst, "Administrador institucional"},
		{rbac.RolCoordinador, "Coordinador de facultad o programa"},
		{rbac.RolDocente, "Docente — puede marcar asistencia"},
		{rbac.RolEstudiante, "Estudiante — puede marcar asistencia (F3)"},
		{rbac.RolMonitor, "Monitor de aula"},
		{rbac.RolAuditor, "Auditor con acceso de solo lectura"},
	}

	upsertOpts := options.Update().SetUpsert(true)
	for _, r := range roles {
		perms := rbac.DefaultPermissions[r.nombre]
		permStrs := make([]string, len(perms))
		for i, p := range perms {
			permStrs[i] = string(p)
		}

		filter := bson.D{{Key: "nombre", Value: string(r.nombre)}}
		update := bson.D{{Key: "$setOnInsert", Value: roleDoc{
			Nombre:      string(r.nombre),
			Descripcion: r.descripcion,
			Permisos:    permStrs,
			Predefinido: true,
			CreadoEn:    now,
		}}}
		if _, err := col.UpdateOne(ctx, filter, update, upsertOpts); err != nil {
			return fmt.Errorf("upsert role %s: %w", r.nombre, err)
		}
	}
	return nil
}
