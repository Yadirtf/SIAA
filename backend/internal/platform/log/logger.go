// Package log provee logging estructurado en JSON con correlationId. T-PLT-01.4, RNF-MAN-005.
package log

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"time"
)

type Level int

const (
	LevelDebug Level = iota
	LevelInfo
	LevelWarn
	LevelError
)

type Logger struct {
	level  Level
	output io.Writer
}

type Entry struct {
	Timestamp     string      `json:"ts"`
	Level         string      `json:"level"`
	Message       string      `json:"msg"`
	CorrelationID string      `json:"correlationId,omitempty"`
	UsuarioID     string      `json:"usuarioId,omitempty"`
	Method        string      `json:"metodo,omitempty"`
	Path          string      `json:"ruta,omitempty"`
	Status        int         `json:"status,omitempty"`
	DurationMs    int64       `json:"duracionMs,omitempty"`
	Error         string      `json:"error,omitempty"`
	Fields        interface{} `json:"fields,omitempty"`
}

var defaultLogger = &Logger{level: LevelInfo, output: os.Stdout}

func Default() *Logger { return defaultLogger }

func New(level Level, w io.Writer) *Logger {
	if w == nil {
		w = os.Stdout
	}
	return &Logger{level: level, output: w}
}

func (l *Logger) write(e Entry) {
	b, err := json.Marshal(e)
	if err != nil {
		fmt.Fprintf(l.output, `{"level":"error","msg":"log marshal error","error":%q}`+"\n", err.Error())
		return
	}
	l.output.Write(append(b, '\n'))
}

func (l *Logger) log(level Level, levelStr, msg string, fields ...Field) {
	if level < l.level {
		return
	}
	e := Entry{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Level:     levelStr,
		Message:   msg,
	}
	for _, f := range fields {
		f(&e)
	}
	l.write(e)
}

func (l *Logger) Debug(msg string, fields ...Field) { l.log(LevelDebug, "debug", msg, fields...) }
func (l *Logger) Info(msg string, fields ...Field)  { l.log(LevelInfo, "info", msg, fields...) }
func (l *Logger) Warn(msg string, fields ...Field)  { l.log(LevelWarn, "warn", msg, fields...) }
func (l *Logger) Error(msg string, fields ...Field) { l.log(LevelError, "error", msg, fields...) }

// Field es una función que decora una entrada de log.
type Field func(*Entry)

func CorrelationID(id string) Field { return func(e *Entry) { e.CorrelationID = id } }
func UsuarioID(id string) Field     { return func(e *Entry) { e.UsuarioID = id } }
func Method(m string) Field         { return func(e *Entry) { e.Method = m } }
func Path(p string) Field           { return func(e *Entry) { e.Path = p } }
func Status(s int) Field            { return func(e *Entry) { e.Status = s } }
func DurationMs(d int64) Field      { return func(e *Entry) { e.DurationMs = d } }
func Err(err error) Field {
	return func(e *Entry) {
		if err != nil {
			e.Error = err.Error()
		}
	}
}
func Extra(v interface{}) Field { return func(e *Entry) { e.Fields = v } }

// ─── Contexto ─────────────────────────────────────────────────
type ctxKey struct{}

func WithLogger(ctx context.Context, l *Logger) context.Context {
	return context.WithValue(ctx, ctxKey{}, l)
}

func FromContext(ctx context.Context) *Logger {
	if l, ok := ctx.Value(ctxKey{}).(*Logger); ok {
		return l
	}
	return defaultLogger
}
