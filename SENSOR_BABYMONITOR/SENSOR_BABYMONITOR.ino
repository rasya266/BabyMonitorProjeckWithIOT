#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include "DHT.h"

// Pin Definitions
#define DHTPIN D2
#define DHTTYPE DHT11
#define LEDPIN D4
#define SOUND_SENSOR_PIN A0

// WiFi credentials
const char* ssid = "ZEUS-5G-2Ee5";
const char* password = "rois2415";

// Server details
const char* serverName = "https://21h5tsf6-3000.asse.devtunnels.ms/data";

// DHT sensor
DHT dht(DHTPIN, DHTTYPE);

// Timer variables
unsigned long lastTime = 0;
unsigned long timerDelay = 5000; // Set timer to 5 seconds (5000 milliseconds)

void setup() {
    Serial.begin(115200); // Ensure the Serial Monitor in Arduino IDE is set to 115200 baud
    dht.begin();

    pinMode(LEDPIN, OUTPUT);
    pinMode(SOUND_SENSOR_PIN, INPUT);

    Serial.println("DHT11 and Sound Sensor Test");

    WiFi.begin(ssid, password);
    Serial.println("Connecting to WiFi...");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("");
    Serial.print("Connected to WiFi network with IP Address: ");
    Serial.println(WiFi.localIP());

    Serial.println("Timer set to 5 seconds (timerDelay variable), it will take 5 seconds before publishing the first reading.");
}

void loop() {
    // Send an HTTP POST request every 5 seconds
    if ((millis() - lastTime) > timerDelay) {
        // Check WiFi connection status
        if (WiFi.status() == WL_CONNECTED) {
            WiFiClientSecure client;
            client.setInsecure(); // Disable certificate validation for testing purposes

            HTTPClient http;

            // Your Domain name with URL path or IP address with path
            http.begin(client, serverName);

            // Specify content-type header
            http.addHeader("Content-Type", "application/json");

            // Reading sound level
            int soundLevel = analogRead(SOUND_SENSOR_PIN);

            // Reading temperature and humidity
            float humidity = dht.readHumidity();
            float temperature = dht.readTemperature();

            // Check if any reads failed
            if (isnan(humidity) || isnan(temperature)) {
                Serial.println("Failed to read from DHT sensor!");
                return;
            }

            // Display the readings
            Serial.print("Temperature: ");
            Serial.print(temperature);
            Serial.print(" *C, Humidity: ");
            Serial.print(humidity);
            Serial.print(" %, Sound Level: ");
            Serial.println(soundLevel);

            // Thresholds
            int soundThreshold = 227;
            float tempThreshold = 33.0;

            // Debugging
            Serial.print("Sound Level: ");
            Serial.print(soundLevel);
            Serial.print(" | Sound Threshold: ");
            Serial.println(soundThreshold);
            Serial.print("Temperature: ");
            Serial.print(temperature);
            Serial.print(" | Temperature Threshold: ");
            Serial.println(tempThreshold);

            // LED control based on thresholds
            if (soundLevel > soundThreshold && temperature >= tempThreshold) {
                Serial.println("LED ON");
                digitalWrite(LEDPIN, HIGH); // Turn on LED
            } else {
                Serial.println("LED OFF");
                digitalWrite(LEDPIN, LOW); // Turn off LED
            }

            // Create a JSON object
            StaticJsonDocument<200> jsonDoc;
            jsonDoc["token"] = "EoC8y_";
            jsonDoc["suhu"] = temperature;
            jsonDoc["kelembapan"] = humidity;
            jsonDoc["suara"] = soundLevel;

            // Serialize JSON object to string
            String jsonData;
            serializeJson(jsonDoc, jsonData);

            // Print the JSON data for debugging
            Serial.print("JSON Data: ");
            Serial.println(jsonData);

            // Send HTTP POST request
            int httpResponseCode = http.POST(jsonData);

            // Print HTTP response code
            Serial.print("HTTP Response code: ");
            Serial.println(httpResponseCode);

            // Print the response payload
            if (httpResponseCode > 0) {
                String payload = http.getString();
                Serial.print("Response payload: ");
                Serial.println(payload);
            }

            // Free resources
            http.end();
        } else {
            Serial.println("WiFi Disconnected");
        }
        lastTime = millis();
    }
}
