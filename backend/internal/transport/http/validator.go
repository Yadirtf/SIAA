package http

import (
	"net/http"
	"strings"

	"github.com/go-playground/validator/v10"
	"github.com/labstack/echo/v4"

	"github.com/siaa/backend/internal/domain/shared"
)

// customValidator conecta go-playground/validator con Echo.
type customValidator struct {
	v *validator.Validate
}

func newValidator() *customValidator {
	v := validator.New()
	return &customValidator{v: v}
}

func (cv *customValidator) Validate(i interface{}) error {
	if err := cv.v.Struct(i); err != nil {
		var fields []shared.FieldError
		if ve, ok := err.(validator.ValidationErrors); ok {
			for _, e := range ve {
				fields = append(fields, shared.FieldError{
					Campo: strings.ToLower(e.Field()),
					Error: e.Tag(),
				})
			}
		}
		return &shared.DomainError{
			Code:    shared.ErrValidacion,
			Message: "Los datos de entrada son inválidos",
			Fields:  fields,
		}
	}
	return nil
}

// Ensure interface compliance
var _ echo.Validator = (*customValidator)(nil)
var _ error = (*shared.DomainError)(nil)

// Silence unused import warning
var _ = http.StatusOK
