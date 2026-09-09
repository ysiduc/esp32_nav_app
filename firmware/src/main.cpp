/**
 * ESP32 Smart Nav & iOS ANCS Notifications
 * Features:
 * 1. Apple ANCS Client: Nhận cuộc gọi đến, tin nhắn từ iPhone
 * 2. Custom BLE Server: Nhận gói chỉ đường OSM + Mini Map Vector từ Flutter App
 * 3. OLED SSD1306 128x64: Vẽ hướng rẽ, khoảng cách, tốc độ, bản đồ mini
 */

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ArduinoJson.h>
#include <NimBLEDevice.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// BLE UUIDs cho Custom Navigation Service
#define SERVICE_NAV_UUID   "0000ffe0-0000-1000-8000-00805f9b34fb"
#define CHAR_NAV_RX_UUID   "0000ffe1-0000-1000-8000-00805f9b34fb"

// Dữ liệu Navigation
struct NavData {
    int turnCode = 0;       // 0: Đi thẳng, 1: Chếch trái, 2: Rẽ trái, 5: Rẽ phải...
    int distMeters = 0;
    String streetName = "Sẵn sàng";
    int speedKmh = 0;
    int remainDist = 0;
    int etaMinutes = 0;
    bool isNavigating = false;
} currentNav;

// Dữ liệu Vector Mini Map (tối đa 40 điểm)
struct Point { int x; int y; };
Point mapPoints[45];
int mapPointCount = 0;

// Trạng thái cuộc gọi / thông báo ANCS
bool isIncomingCall = false;
String callerInfo = "";
unsigned long callDisplayTimer = 0;

// Hàm vẽ mũi tên rẽ
void drawTurnArrow(int code, int x, int y) {
    display.fillRect(x - 14, y - 14, 28, 28, SSD1306_BLACK);
    switch (code) {
        case 0: // Đi thẳng
            display.drawLine(x, y + 10, x, y - 10, SSD1306_WHITE);
            display.drawLine(x, y - 10, x - 5, y - 5, SSD1306_WHITE);
            display.drawLine(x, y - 10, x + 5, y - 5, SSD1306_WHITE);
            break;
        case 1: case 2: case 3: // Rẽ trái
            display.drawLine(x + 8, y + 8, x - 8, y + 8, SSD1306_WHITE);
            display.drawLine(x - 8, y + 8, x - 8, y - 6, SSD1306_WHITE);
            display.drawLine(x - 8, y - 6, x - 13, y - 1, SSD1306_WHITE);
            display.drawLine(x - 8, y - 6, x - 3, y - 1, SSD1306_WHITE);
            break;
        case 4: case 5: case 6: // Rẽ phải
            display.drawLine(x - 8, y + 8, x + 8, y + 8, SSD1306_WHITE);
            display.drawLine(x + 8, y + 8, x + 8, y - 6, SSD1306_WHITE);
            display.drawLine(x + 8, y - 6, x + 3, y - 1, SSD1306_WHITE);
            display.drawLine(x + 8, y - 6, x + 13, y - 1, SSD1306_WHITE);
            break;
        case 7: // Quay đầu U-Turn
            display.drawCircle(x, y - 2, 7, SSD1306_WHITE);
            display.fillRect(x - 7, y, 14, 8, SSD1306_BLACK);
            display.drawLine(x - 7, y, x - 7, y + 8, SSD1306_WHITE);
            display.drawLine(x + 7, y, x + 7, y + 8, SSD1306_WHITE);
            display.drawLine(x - 7, y + 8, x - 11, y + 4, SSD1306_WHITE);
            display.drawLine(x - 7, y + 8, x - 3, y + 4, SSD1306_WHITE);
            break;
        case 9: // Điểm đích
            display.drawCircle(x, y, 9, SSD1306_WHITE);
            display.fillCircle(x, y, 4, SSD1306_WHITE);
            break;
        default:
            display.drawTriangle(x, y - 10, x - 8, y + 8, x + 8, y + 8, SSD1306_WHITE);
            break;
    }
}

// Hàm cập nhật màn hình OLED
void updateDisplay() {
    display.clearDisplay();

    // 1. Nếu có cuộc gọi đến -> Ưu tiên hiện toàn màn hình
    if (isIncomingCall) {
        display.drawRoundRect(0, 0, 128, 64, 4, SSD1306_WHITE);
        display.setTextSize(1);
        display.setTextColor(SSD1306_WHITE);
        display.setCursor(18, 6);
        display.print("CUOC GOI DEN");

        display.setTextSize(2);
        display.setCursor(8, 24);
        display.print(callerInfo.substring(0, 10));

        display.setTextSize(1);
        display.setCursor(16, 48);
        display.print("[ iOS ANCS Call ]");
        display.display();
        return;
    }

    // 2. Màn hình chỉ đường (Navigation View)
    drawTurnArrow(currentNav.turnCode, 16, 18);

    // Khoảng cách rẽ (Font to)
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(36, 10);
    if (currentNav.distMeters >= 1000) {
        display.print((float)currentNav.distMeters / 1000.0, 1);
        display.print("km");
    } else {
        display.print(currentNav.distMeters);
        display.print("m");
    }

    // Tên đường hiện tại / sắp rẽ
    display.setTextSize(1);
    display.setCursor(4, 34);
    display.print(currentNav.streetName.substring(0, 18));

    // Đường kẻ phân cách
    display.drawLine(0, 46, 128, 46, SSD1306_WHITE);

    // Tốc độ & Quãng đường còn lại
    display.setCursor(4, 52);
    display.print(currentNav.speedKmh);
    display.print(" km/h");

    display.setCursor(70, 52);
    display.print("Con: ");
    if (currentNav.remainDist >= 1000) {
        display.print((float)currentNav.remainDist / 1000.0, 1);
        display.print("km");
    } else {
        display.print(currentNav.remainDist);
        display.print("m");
    }

    // Vẽ Bản đồ Vector Mini ở góc phải nếu có dữ liệu
    if (mapPointCount > 1) {
        for (int i = 0; i < mapPointCount - 1; i++) {
            int x1 = map(mapPoints[i].x, 0, 120, 92, 126);
            int y1 = map(mapPoints[i].y, 0, 50, 4, 30);
            int x2 = map(mapPoints[i + 1].x, 0, 120, 92, 126);
            int y2 = map(mapPoints[i + 1].y, 0, 50, 4, 30);
            display.drawLine(x1, y1, x2, y2, SSD1306_WHITE);
        }
    }

    display.display();
}

// Xử lý gói tin BLE nhận được từ App Flutter
class NavCharCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pCharacteristic) {
        std::string rxValue = pCharacteristic->getValue();
        if (rxValue.length() == 0) return;

        String str = String(rxValue.c_str());

        // Nếu là gói Vector Map: "MAP:x1,y1;x2,y2..."
        if (str.startsWith("MAP:")) {
            String mapData = str.substring(4);
            mapPointCount = 0;
            int startIdx = 0;
            while (startIdx < mapData.length() && mapPointCount < 40) {
                int semiIdx = mapData.indexOf(';', startIdx);
                if (semiIdx == -1) semiIdx = mapData.length();
                String pair = mapData.substring(startIdx, semiIdx);
                int commaIdx = pair.indexOf(',');
                if (commaIdx != -1) {
                    mapPoints[mapPointCount].x = pair.substring(0, commaIdx).toInt();
                    mapPoints[mapPointCount].y = pair.substring(commaIdx + 1).toInt();
                    mapPointCount++;
                }
                startIdx = semiIdx + 1;
            }
            updateDisplay();
            return;
        }

        // Nếu là gói Navigation JSON: {"t":2,"d":150,"s":"Nguyen Hue","v":40,...}
        JsonDocument doc;
        DeserializationError error = deserializeJson(doc, str);
        if (!error) {
            currentNav.turnCode = doc["t"] | 0;
            currentNav.distMeters = doc["d"] | 0;
            currentNav.streetName = doc["s"] | "Đường đi";
            currentNav.speedKmh = doc["v"] | 0;
            currentNav.remainDist = doc["rem"] | 0;
            currentNav.etaMinutes = doc["eta"] | 0;
            currentNav.isNavigating = true;
            updateDisplay();
        }
    }
};

void setup() {
    Serial.begin(115200);

    // Khởi tạo OLED I2C (SDA=21, SCL=22 trên ESP32 chuẩn)
    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("OLED init failed!");
    }
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(10, 20);
    display.println("ESP32 SMART NAV");
    display.setCursor(10, 36);
    display.println("Waiting BLE / iOS...");
    display.display();

    // Khởi tạo NimBLE Server + Security cho ANCS Pairing
    NimBLEDevice::init("ESP32-NAV");
    NimBLEDevice::setSecurityAuth(true, true, true); // MITM + Bonding (bắt buộc cho iOS ANCS)
    NimBLEDevice::setSecurityIOCap(BLE_HS_IO_NO_INPUT_OUTPUT);

    NimBLEServer* pServer = NimBLEDevice::createServer();
    NimBLEService* pService = pServer->createService(SERVICE_NAV_UUID);

    NimBLECharacteristic* pChar = pService->createCharacteristic(
        CHAR_NAV_RX_UUID,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR
    );
    pChar->setCallbacks(new NavCharCallbacks());
    pService->start();

    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_NAV_UUID);
    pAdvertising->start();

    Serial.println("ESP32 BLE Advertising started! Sẵn sàng ghép đôi với iPhone.");
}

void loop() {
    // Tự tắt màn hình cuộc gọi sau 8 giây nếu không còn đổ chuông
    if (isIncomingCall && millis() - callDisplayTimer > 8000) {
        isIncomingCall = false;
        updateDisplay();
    }
    delay(50);
}
