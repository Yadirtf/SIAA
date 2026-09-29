package shared

import (
	"crypto/rand"
	"encoding/binary"
	"encoding/hex"
	"sync/atomic"
	"time"

	"github.com/google/uuid"
)

var idCounter = func() uint32 {
	var b [4]byte
	_, _ = rand.Read(b[:])
	return binary.BigEndian.Uint32(b[:])
}()

var idProcessUnique = func() [5]byte {
	var b [5]byte
	_, _ = rand.Read(b[:])
	return b
}()

// NewID genera un identificador único de aplicación de 24 caracteres hexadecimales,
// con el mismo formato de un ObjectID de MongoDB (4 bytes de tiempo + 5 aleatorios
// por proceso + 3 de contador). Así el ID que el caso de uso asigna a una entidad
// es exactamente el _id con el que el repositorio la persiste y la vuelve a buscar.
// Se genera sin depender del driver de MongoDB para mantener el dominio puro (ADR-02).
func NewID() string {
	var b [12]byte
	binary.BigEndian.PutUint32(b[0:4], uint32(time.Now().Unix()))
	copy(b[4:9], idProcessUnique[:])
	c := atomic.AddUint32(&idCounter, 1)
	b[9], b[10], b[11] = byte(c>>16), byte(c>>8), byte(c)
	return hex.EncodeToString(b[:])
}

// NewInstallationID genera un UUID estable para identificar una instalación de app.
// Equivalente al "identificador de instalación" del SRS (no IMEI, no ad ID).
func NewInstallationID() string {
	return uuid.New().String()
}
