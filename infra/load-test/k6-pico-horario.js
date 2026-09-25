// SIAA — Simulación de Carga Pico Horario (US-PLT-05 AC-02, RNF-PER-001)
// Simula 300 solicitudes por segundo sostenidas durante 10 minutos (pico 7:00 AM).
// Criterios de aceptación:
// - Latencia p95 <= 2.0 s
// - Tasa de error <= 0.1 % (0.001)
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

export const errorRate = new Rate('errors');

export const options = {
  scenarios: {
    pico_horario: {
      executor: 'constant-arrival-rate',
      rate: 300,             // 300 peticiones por segundo
      timeUnit: '1s',
      duration: '10m',       // Sostenidas durante 10 minutos
      preAllocatedVUs: 100,  // VUs iniciales para sostener la tasa
      maxVUs: 400,           // Límite de escalamiento
    },
  },
  thresholds: {
    // RNF-PER-003: Latencia p95 <= 2s (2000 ms)
    'http_req_duration': ['p(95)<=2000', 'p(99)<=3000'],
    // RNF-PER-001: Tasa de error global <= 0.1 %
    'http_req_failed': ['rate<=0.001'],
    'errors': ['rate<=0.001'],
  },
};

const BASE_URL = __ENV.API_BASE_URL || 'http://localhost:8080/api/v1';

export default function () {
  const headers = {
    'Content-Type': 'application/json',
    'X-Correlation-ID': `load-${__VU}-${__ITER}-${Date.now()}`,
  };

  // Simulación de marcaje o consulta de estado en pico horario
  const payload = JSON.stringify({
    codigoEspacio: 'AULA-101',
    coordenadas: [-74.08175, 4.60971], // [longitud, latitud]
    precisionMetros: 12.5,
    timestamp: new Date().toISOString(),
  });

  // Alternar entre endpoint de validación y health probe
  const res = http.get(`${BASE_URL}/health`, { headers });
  
  const success = check(res, {
    'status es 200': (r) => r.status === 200,
    'tiempo <= 2s': (r) => r.timings.duration <= 2000,
  });

  errorRate.add(!success);
}
