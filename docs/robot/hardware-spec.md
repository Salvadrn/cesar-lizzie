# Adapt AI — Robot Seguidor Medico — Especificacion de Hardware

## Drivetrain
- **Tipo**: Swerve central (1 modulo) + 4 ruedas locas (casters)
- **Motor de traccion**: REV NEO 550 + SPARK MAX controller
- **Motor de direccion**: REV NEO 550 + SPARK MAX controller
- **Control**: PWM desde Raspberry Pi (los SPARK MAX aceptan PWM estandar 1000-2000us)

## Cerebro
- **Computadora**: Raspberry Pi 4 (4GB) o RPi 5
- **OS**: Raspberry Pi OS (64-bit)
- **Lenguaje**: Python 3.11+

## Sensores
- **Seguimiento**: BLE integrado de la RPi (sigue el iPhone del paciente)
- **Obstaculos**: RPLiDAR A1M8 (360°, USB serial)
- **Emergencia**: 2x HC-SR04 ultrasonicos (frente izq/der)

## Comunicacion
- **WiFi**: RPi WiFi integrado → backend Adapt AI (Socket.IO)
- **BLE**: RPi BLE integrado → iPhone del paciente (tracking RSSI)

## Alimentacion
- **Bateria**: LiPo 11.1V 3S 5000mAh (alimenta NEOs via SPARK MAX)
- **RPi**: Step-down 5V 3A (LM2596 o BEC)
- **LiDAR**: 5V desde RPi o BEC separado

## Conexiones RPi GPIO
| Pin | Funcion |
|-----|---------|
| GPIO 18 (PWM0) | SPARK MAX — motor traccion |
| GPIO 12 (PWM1) | SPARK MAX — motor direccion |
| GPIO 23 | HC-SR04 izquierdo — trigger |
| GPIO 24 | HC-SR04 izquierdo — echo |
| GPIO 25 | HC-SR04 derecho — trigger |
| GPIO 8 | HC-SR04 derecho — echo |
| USB | RPLiDAR A1 (serial /dev/ttyUSB0) |

## SPARK MAX — Control PWM
Los SPARK MAX aceptan senal PWM estandar:
- **1500us** = neutro (motor parado)
- **1000us** = full reverse
- **2000us** = full forward
- **Frecuencia**: 50Hz (servo standard) o hasta 200Hz

### Configuracion SPARK MAX
1. Usar REV Hardware Client para configurar cada SPARK MAX:
   - Motor type: Brushless
   - Input mode: PWM
   - Idle mode: Brake (para el robot de seguridad)
   - Current limit: 20A (proteccion NEO 550)
2. Un SPARK MAX para drive (traccion)
3. Un SPARK MAX para steer (direccion) — configurar soft limits para +-90°

## Dimensiones Estimadas
- **Base**: 40cm x 30cm
- **Altura**: 25cm (sin sensores)
- **Peso estimado**: 4-5 kg

## Lista de Materiales (BOM)

| Componente | Cantidad | Precio Aprox |
|---|---|---|
| Raspberry Pi 4 (4GB) | 1 | $55 USD |
| REV NEO 550 | 2 | $50 USD ($25 c/u) |
| REV SPARK MAX | 2 | $150 USD ($75 c/u) |
| RPLiDAR A1M8 | 1 | $100 USD |
| HC-SR04 | 2 | $4 USD |
| LiPo 11.1V 3S 5000mAh | 1 | $25 USD |
| BEC/Step-down 5V 3A | 1 | $5 USD |
| Caster wheels | 4 | $12 USD |
| Chasis/frame (aluminio/3D print) | 1 | $30 USD |
| Cables, conectores, misc | - | $15 USD |
| **TOTAL** | | **~$446 USD** |
