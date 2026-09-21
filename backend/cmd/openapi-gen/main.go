package main

import (
	"encoding/json"
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

func main() {
	yamlBytes, err := os.ReadFile("../../contracts/openapi.yaml")
	if err != nil {
		// Try alternative relative path
		yamlBytes, err = os.ReadFile("../contracts/openapi.yaml")
		if err != nil {
			yamlBytes, err = os.ReadFile("contracts/openapi.yaml")
		}
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error leyendo openapi.yaml: %v\n", err)
		os.Exit(1)
	}

	var node yaml.Node
	if err := yaml.Unmarshal(yamlBytes, &node); err != nil {
		fmt.Fprintf(os.Stderr, "Error des-serializando openapi.yaml: %v\n", err)
		os.Exit(1)
	}

	var obj interface{}
	if err := node.Decode(&obj); err != nil {
		fmt.Fprintf(os.Stderr, "Error decodificando nodo: %v\n", err)
		os.Exit(1)
	}

	jsonBytes, err := json.MarshalIndent(obj, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error serializando a JSON: %v\n", err)
		os.Exit(1)
	}

	outPaths := []string{
		"../../contracts/openapi.json",
		"../contracts/openapi.json",
		"contracts/openapi.json",
	}

	written := false
	for _, p := range outPaths {
		if err := os.WriteFile(p, jsonBytes, 0644); err == nil {
			fmt.Printf("Generado: %s\n", p)
			written = true
			break
		}
	}
	if !written {
		fmt.Fprintf(os.Stderr, "No se pudo escribir openapi.json\n")
		os.Exit(1)
	}
}
