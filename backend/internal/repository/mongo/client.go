// Package mongo provee la conexión y el cliente MongoDB del sistema.
// T-PLT-01.6: pool de conexiones configurado, timeout explícito.
// Las migraciones de índices y la siembra de datos viven en sub-paquetes
// dedicados: migrations/ y seed/.
package mongo

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/readpref"
)

// Client envuelve el cliente oficial de MongoDB con el nombre de la base de datos.
// Es el único punto de acceso a las colecciones en todo el sistema.
type Client struct {
	db     *mongo.Database
	client *mongo.Client
}

// Connect crea, configura y verifica la conexión a MongoDB.
// Devuelve error si no puede alcanzar el servidor dentro del contexto dado.
func Connect(ctx context.Context, uri, dbName string) (*Client, error) {
	opts := options.Client().
		ApplyURI(uri).
		SetConnectTimeout(10 * time.Second).
		SetServerSelectionTimeout(10 * time.Second).
		SetMaxPoolSize(100).
		SetMinPoolSize(5)

	client, err := mongo.Connect(ctx, opts)
	if err != nil {
		return nil, fmt.Errorf("mongo connect: %w", err)
	}

	if err := client.Ping(ctx, readpref.Primary()); err != nil {
		return nil, fmt.Errorf("mongo ping: %w", err)
	}

	return &Client{db: client.Database(dbName), client: client}, nil
}

// Disconnect cierra la conexión de forma ordenada al apagar el servidor.
func (c *Client) Disconnect(ctx context.Context) error {
	return c.client.Disconnect(ctx)
}

// Ping verifica que la conexión siga activa. Usado por /health/ready.
func (c *Client) Ping(ctx context.Context) error {
	return c.client.Ping(ctx, readpref.Primary())
}

// Collection retorna una colección por nombre.
func (c *Client) Collection(name string) *mongo.Collection {
	return c.db.Collection(name)
}

// DB retorna la base de datos subyacente.
// Solo debe usarse por los paquetes de migración e implementación de repositorios.
func (c *Client) DB() *mongo.Database { return c.db }
