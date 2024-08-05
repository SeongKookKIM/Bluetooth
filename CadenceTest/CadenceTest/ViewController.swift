//
//  ViewController.swift
//  CadenceTest
//
//  Created by SeongKook on 7/31/24.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var lastCrankEventTime: UInt16 = 0
    var lastCrankRevolutions: UInt16 = 0
    var lastWheelEventTime: UInt16 = 0
    var lastWheelRevolutions: UInt32 = 0

    var consecutiveZeroCount = 0
    let maxConsecutiveZeros = 3

    var lastValidCadence: Double = 0
    var lastValidSpeed: Double = 0
    var isFirstMeasurement = true
    let validCadenceTimeout: TimeInterval = 2 // seconds
    var lastValidCadenceTime: Date?
    
    var totalDistance: Double = 0 // 총 이동 거리 (km)
    var totalCalories: Double = 0 // 총 소모 칼로리 (kcal)
    var lastUpdateTime: Date? // 마지막 업데이트 시간
    var userWeight: Double = 70 // 사용자 체중 (kg), 기본값 70kg

    var timer: Timer?
    var isRunning = false
    var startTime: Date?
    var elapsedTime: TimeInterval = 0

    var connectButton: UIButton!
    var disconnectButton: UIButton!
    var startStopButton: UIButton!
    var cadenceLabel: UILabel!
    var speedLabel: UILabel!
    var statusLabel: UILabel!
    var deviceNameLabel: UILabel!
    var distanceLabel: UILabel!
    var caloriesLabel: UILabel!
    var timerLabel: UILabel!
    
    var centralManager: CBCentralManager!
    var cadencePeripheral: CBPeripheral?
    
    let cadenceServiceUUID = CBUUID(string: "1816")
    let cadenceCharacteristicUUID = CBUUID(string: "2A5B")
    
    let wheelCircumference: Double = 2105
    
    /* 블루투스 sheet
     */
    var discoveredPeripherals: [CBPeripheral] = []
    var bluetoothListSheet: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func setupUI() {
        connectButton = UIButton(type: .system)
        connectButton.setTitle("장치연결", for: .normal)
        connectButton.addTarget(self, action: #selector(connectPressed), for: .touchUpInside)
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(connectButton)
        
        disconnectButton = UIButton(type: .system)
        disconnectButton.setTitle("블루투스 연결끊기", for: .normal)
        disconnectButton.addTarget(self, action: #selector(disconnectPressed), for: .touchUpInside)
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(disconnectButton)
        
        startStopButton = UIButton(type: .system)
        startStopButton.setTitle("시작", for: .normal)
        startStopButton.addTarget(self, action: #selector(startStopPressed), for: .touchUpInside)
        startStopButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startStopButton)
        
        cadenceLabel = UILabel()
        cadenceLabel.text = "Cadence: "
        cadenceLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        cadenceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cadenceLabel)
        
        speedLabel = UILabel()
        speedLabel.text = "Speed: "
        speedLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedLabel)
        
        statusLabel = UILabel()
        statusLabel.text = "상태: Disconnected"
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        deviceNameLabel = UILabel()
        deviceNameLabel.text = "Device: N/A"
        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deviceNameLabel)
        
        distanceLabel = UILabel()
        distanceLabel.text = "Distance: 0.00 km"
        distanceLabel.font = UIFont.systemFont(ofSize: 40, weight: .regular)
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(distanceLabel)

        caloriesLabel = UILabel()
        caloriesLabel.text = "Calories: 0 kcal"
        caloriesLabel.font = UIFont.systemFont(ofSize: 40, weight: .regular)
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(caloriesLabel)
        
        timerLabel = UILabel()
        timerLabel.text = "00:00"
        timerLabel.font = UIFont.systemFont(ofSize: 40, weight: .heavy)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerLabel)

        setupConstraints()
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            connectButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            disconnectButton.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            disconnectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            timerLabel.topAnchor.constraint(equalTo: disconnectButton.bottomAnchor, constant: 20),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cadenceLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 20),
            cadenceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            speedLabel.topAnchor.constraint(equalTo: cadenceLabel.bottomAnchor, constant: 20),
            speedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            distanceLabel.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 20),
            distanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            caloriesLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 10),
            caloriesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: caloriesLabel.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            deviceNameLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            deviceNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            startStopButton.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 20),
            startStopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
//    @objc func connectPressed() {
//        centralManager.scanForPeripherals(withServices: [cadenceServiceUUID], options: nil)
//    }
    
    @objc func disconnectPressed() {
        if let peripheral = cadencePeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    @objc func startStopPressed() {
        if isRunning {
            stopTimer()
            startStopButton.setTitle("시작", for: .normal)
        } else {
            startTimer()
            startStopButton.setTitle("정지", for: .normal)
        }
    }

    func startTimer() {
        isRunning = true
        startTime = Date()
        lastUpdateTime = Date()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }

    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    @objc func timerFired() {
        if isRunning {
            updateDistanceAndCalories(speed: lastValidSpeed)
            updateTimerLabel()
        }
    }

    func updateTimerLabel() {
        if let startTime = startTime {
            elapsedTime = Date().timeIntervalSince(startTime)
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [cadenceServiceUUID], options: nil)
        } else {
            print("Bluetooth is not available.")
        }
    }
    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        print("Discovered peripheral: \(peripheral.name ?? "Unknown")")
//        cadencePeripheral = peripheral
//        cadencePeripheral?.delegate = self
//        centralManager.stopScan()
//        centralManager.connect(peripheral, options: nil)
//    }
    // 블루투스 Sheet
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            DispatchQueue.main.async {
                self.updateBluetoothListSheet()
            }
        }
    }


    
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
//        peripheral.discoverServices([cadenceServiceUUID])
//        DispatchQueue.main.async {
//            self.statusLabel.text = "상태: Connected"
//            self.deviceNameLabel.text = "Device: \(peripheral.name ?? "Unknown")"
//        }
//    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
        peripheral.discoverServices([cadenceServiceUUID])
        DispatchQueue.main.async {
            self.statusLabel.text = "상태: Connected"
            self.deviceNameLabel.text = "Device: \(peripheral.name ?? "Unknown")"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == cadencePeripheral {
            print("Disconnected from peripheral")
            cadencePeripheral = nil
            centralManager.scanForPeripherals(withServices: [cadenceServiceUUID], options: nil)
            DispatchQueue.main.async {
                self.statusLabel.text = "상태: Disconnected"
                self.deviceNameLabel.text = "Device: N/A"
            }
        }
    }
    
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        if let services = peripheral.services {
//            for service in services {
//                print("Discovered service: \(service.uuid)")
//                if service.uuid == cadenceServiceUUID {
//                    peripheral.discoverCharacteristics([cadenceCharacteristicUUID], for: service)
//                }
//            }
//        }
//    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == cadenceServiceUUID {
                peripheral.discoverCharacteristics([cadenceCharacteristicUUID], for: service)
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Discovered characteristic: \(characteristic.uuid)")
                if characteristic.uuid == cadenceCharacteristicUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == cadenceCharacteristicUUID {
            if let data = characteristic.value {
                print("Received data: \(data.map { String(format: "%02X", $0) }.joined())")
                parseCadenceData(data)
            } else {
                print("Characteristic value is nil")
            }
        }
    }
    
    func parseCadenceData(_ data: Data) {
        guard data.count >= 5 else {
            print("Data length is less than 5 bytes")
            return
        }

        let crankRevolutions = UInt16(data[1]) | (UInt16(data[2]) << 8)
        let crankEventTime = UInt16(data[3]) | (UInt16(data[4]) << 8)

        print("Parsed Crank Revolutions: \(crankRevolutions)")
        print("Parsed Crank Event Time: \(crankEventTime)")

        var cadence: Double = 0
        var speed: Double = 0

        if !isFirstMeasurement {
            let crankDiff = (crankRevolutions >= lastCrankRevolutions) ? (crankRevolutions - lastCrankRevolutions) : (crankRevolutions &+ (0xFFFF - lastCrankRevolutions))
            let crankTimeDiff = (crankEventTime >= lastCrankEventTime) ? (crankEventTime - lastCrankEventTime) : (crankEventTime &+ (0xFFFF - lastCrankEventTime))

            if crankTimeDiff > 0 {
                cadence = Double(crankDiff) / (Double(crankTimeDiff) / 1024.0) * 60.0
            }

            if data.count >= 11 {
                let wheelRevolutions = UInt32(data[5]) | (UInt32(data[6]) << 8) | (UInt32(data[7]) << 16) | (UInt32(data[8]) << 24)
                let wheelEventTime = UInt16(data[9]) | (UInt16(data[10]) << 8)

                print("Parsed Wheel Revolutions: \(wheelRevolutions)")
                print("Parsed Wheel Event Time: \(wheelEventTime)")

                let wheelDiff = (wheelRevolutions >= lastWheelRevolutions) ? (wheelRevolutions - lastWheelRevolutions) : (wheelRevolutions &+ (0xFFFFFFFF - lastWheelRevolutions))
                let wheelTimeDiff = (wheelEventTime >= lastWheelEventTime) ? (wheelEventTime - lastWheelEventTime) : (wheelEventTime &+ (0xFFFF - lastWheelEventTime))

                if wheelTimeDiff > 0 {
                    let wheelRPM = Double(wheelDiff) / (Double(wheelTimeDiff) / 1024.0) * 60.0
                    speed = wheelRPM * wheelCircumference / 60000.0
                }

                print("Wheel Diff: \(wheelDiff)")
                print("Wheel Time Diff: \(wheelTimeDiff)")

                lastWheelRevolutions = wheelRevolutions
                lastWheelEventTime = wheelEventTime
            } else {
                speed = estimateSpeedFromCadence(cadence)
            }
        } else {
            isFirstMeasurement = false
        }

        if cadence > 0 {
            lastValidCadence = cadence
            lastValidCadenceTime = Date()
        }

        if speed > 0 {
            lastValidSpeed = speed
        }

        let currentTime = Date()
        if cadence == 0 && lastValidCadenceTime != nil && currentTime.timeIntervalSince(lastValidCadenceTime!) < validCadenceTimeout {
            cadence = lastValidCadence
            speed = estimateSpeedFromCadence(cadence)
        }

        updateUI(cadence: cadence, speed: speed)

        if cadence == 0 {
            consecutiveZeroCount += 1
            if consecutiveZeroCount >= maxConsecutiveZeros {
                lastValidCadence = 0
                lastValidSpeed = 0
            }
        } else {
            consecutiveZeroCount = 0
        }

        print("Cadence: \(cadence)")
        print("Speed: \(speed)")

        lastCrankRevolutions = crankRevolutions
        lastCrankEventTime = crankEventTime
        
        updateDistanceAndCalories(speed: speed)

        print("Total Distance: \(totalDistance)")
        print("Total Calories: \(totalCalories)")
        print("====================")
    }

    func updateUI(cadence: Double, speed: Double) {
        DispatchQueue.main.async {
            self.cadenceLabel.text = String(format: "Cadence: %.1f RPM", cadence)
            self.speedLabel.text = String(format: "Speed: %.2f km/h", speed)
            self.distanceLabel.text = String(format: "Distance: %.2f km", self.totalDistance)
            self.caloriesLabel.text = String(format: "Calories: %.0f kcal", self.totalCalories)
        }
    }
    
    func estimateSpeedFromCadence(_ cadence: Double) -> Double {
        // cadence: 분당 회전수 (RPM)
        // wheelCircumference: 바퀴 둘레 (mm)
        let rotationsPerHour = cadence * 60 // 시간당 회전수
        let distancePerHour = rotationsPerHour * wheelCircumference / 1000000 // km/h
        return distancePerHour
    }
    
    func updateDistanceAndCalories(speed: Double) {
        let currentTime = Date()
        if let lastTime = lastUpdateTime {
            let timeInterval = currentTime.timeIntervalSince(lastTime) / 3600 // 시간 단위로 변환
            let distance = speed * timeInterval // km
            totalDistance += distance
            
            // MET 값을 사용한 칼로리 계산 (대략적인 추정)
            let met = estimateMET(speed: speed)
            let calories = met * userWeight * timeInterval
            totalCalories += calories
            
            updateDistanceAndCaloriesUI()
        }
        lastUpdateTime = currentTime
    }

    func estimateMET(speed: Double) -> Double {
        // 속도에 따른 대략적인 MET 값 (매우 간단한 추정)
        if speed < 16 { // 느린 속도
            return 4
        } else if speed < 20 { // 중간 속도
            return 6
        } else { // 빠른 속도
            return 8
        }
    }

    func updateDistanceAndCaloriesUI() {
        DispatchQueue.main.async {
            self.distanceLabel.text = String(format: "Distance: %.2f km", self.totalDistance)
            self.caloriesLabel.text = String(format: "Calories: %.0f kcal", self.totalCalories)
        }
    }
    
    func showBluetoothListSheet() {
        let sheet = UIAlertController(title: "사용 가능한 블루투스 장치", message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            self?.centralManager.stopScan()
        }
        sheet.addAction(cancelAction)
        
        present(sheet, animated: true, completion: nil)
    }

    func updateBluetoothListSheet() {
        // 새로운 UIAlertController 생성
        let newSheet = UIAlertController(title: "사용 가능한 블루투스 장치", message: nil, preferredStyle: .actionSheet)
        
        // 장치 목록 추가
        for peripheral in discoveredPeripherals {
            let action = UIAlertAction(title: peripheral.name ?? "Unknown Device", style: .default) { [weak self] _ in
                self?.connectToPeripheral(peripheral)
            }
            newSheet.addAction(action)
        }
        
        // 취소 액션 추가
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            self?.centralManager.stopScan()
        }
        newSheet.addAction(cancelAction)
        
        // 이전 시트를 dismiss하고 새 시트를 표시
        if let presentedSheet = presentedViewController as? UIAlertController {
            presentedSheet.dismiss(animated: true) { [weak self] in
                self?.present(newSheet, animated: true, completion: nil)
            }
        } else {
            present(newSheet, animated: true, completion: nil)
        }
    }

    func connectToPeripheral(_ peripheral: CBPeripheral) {
        centralManager.stopScan()
        cadencePeripheral = peripheral
        cadencePeripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
        dismiss(animated: true, completion: nil)
    }
    
    // 블루투스
    @objc func connectPressed() {
        discoveredPeripherals.removeAll()
        updateBluetoothListSheet()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
}
