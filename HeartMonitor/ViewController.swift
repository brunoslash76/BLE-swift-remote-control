//
//  ViewController.swift
//  Bluetooth Remote Controll HM-10 BLE
//
//  Created by Bruno Russo on 24/06/20.
//  Copyright © 2020 Bruno Russo. All rights reserved.
//

import UIKit
import CoreBluetooth

let hmSoftBLE = CBUUID.init(string: "FFE0")

class ViewController: UIViewController {
    
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var conectionIndicator: UIView!
    @IBOutlet weak var controlContainerView: UIView!
    @IBOutlet weak var glassCapView: UIImageView!
    @IBOutlet weak var bluetoothSignalStrenthImage: UIImageView!
    @IBOutlet weak var signalContainerView: UIView!
    @IBOutlet weak var switchConnectToggle: UISwitch!
    @IBOutlet weak var connectionText: UILabel!
    @IBOutlet weak var toggleConnectionView: UIView!
    @IBOutlet weak var signalContainer: UIView!
    
    private var centralManager: CBCentralManager!
    private var hmsoftPeripheral: CBPeripheral!
    private var characteristic: CBCharacteristic!
    
    private var timer: Timer!
    private var rssValue: NSNumber!
    
    private var isRobotOn = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        initializeUIComponents()
        navigationItem.title = "Remote Control"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        disconnectFromBluetooth()
        cancelTimer()
        print("Disapear")
    }
    
    @IBAction func onPressButtonSend(_ sender: UIButton) {
        switchButtonTag(with: sender.tag)
    }
    
    @IBAction func toggleConnectBluetooth(_ sender: Any) {
        if switchConnectToggle.isOn {
            connectToBluetooth()
            connectionText.text = "on"
            connectionText.textColor = UIColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1)
        } else {
            disconnectFromBluetooth()
            connectionText.text = "off"
            connectionText.textColor = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)
            cancelTimer()
        }
    }
    
    private func connectToBluetooth() {
        centralManager.connect(hmsoftPeripheral, options: nil)
    }
    
    private func disconnectFromBluetooth() {
        centralManager.cancelPeripheralConnection(hmsoftPeripheral)
    }
    
    private func cancelTimer() {
        timer.invalidate()
    }
    
}

// MARK: - CBCentral Manager Delegate
extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
          print("central.state is .unknown")
        case .resetting:
          print("central.state is .resetting")
        case .unsupported:
          print("central.state is .unsupported")
        case .unauthorized:
          print("central.state is .unauthorized")
        case .poweredOff:
          print("central.state is .poweredOff")
            print("IS FUCKING OFF ========================>>>>>>")
          // I HAVE TO REFACTOR HERE
            setConnectionIndicatorOffUI()
            setBluetoothSignalStrenthNoSignalImage()
            setSignalContainerOffView()
            disconnectFromBluetooth()
            isRobotOn = false
        case .poweredOn:
          print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [hmSoftBLE])
        default:
            print("central.state is I really dont know")
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("DISCONECTED")
        setConnectionIndicatorOffUI()
        setBluetoothSignalStrenthNoSignalImage()
        setSignalContainerOffView()
        disconnectFromBluetooth()
        animateView(shouldGo: true)
        isRobotOn = false
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("DISCOVERED =>", peripheral)
        hmsoftPeripheral = peripheral
        hmsoftPeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(hmsoftPeripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("CONNECTED TO PERIPHERAL =>", peripheral)
        setSignalContainerOnView()
        hmsoftPeripheral.discoverServices(nil)
        setConnectionIndicatorOnUI()
        animateView(shouldGo: false)
        isRobotOn = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (_) in
            self.checkBLESignalStrenth()
        })
    }
    
}

// MARK: - CPPeripheral Delegate
extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            
            if characteristic.properties.contains(.writeWithoutResponse)  {
                self.characteristic = characteristic
                if let title = characteristic.value {
                    let title = NSString(
                        data: title,
                        encoding: String.Encoding.utf8.rawValue
                        ) as String?
                    navigationItem.title = title
                }
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case hmSoftBLE:
            self.characteristic = characteristic
            break
        default:
            print("Default", characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.switchBluetoothSignalStrenthImage(signalStrenth: RSSI.intValue)
    }
    
    private func checkBLESignalStrenth() {
        hmsoftPeripheral.readRSSI()
    }
    
}

// MARK: - User Interaction Controllers
extension ViewController {
    // User Interaction
    private func toggleButtonEnabled(with params: Int) {
        switch params {
        case 1...4:
            enableStopButton()
            break
        case 5:
            disableStopButton()
        default:
            disableStopButton()
        }
    }
    
    private func enableStopButton() {
        stopButton.setImage(UIImage(named: "pause-on"), for: .normal)
        stopButton.isEnabled = true
    }
    
    private func disableStopButton() {
        stopButton.setImage(UIImage(named: "pause-off"), for: .normal)
        stopButton.isEnabled = false
    }
    
    fileprivate func switchButtonTag(with tag: Int) {
        switch tag {
        case 1:
            print("pressed button = ", tag)
            toggleButtonEnabled(with: tag)
            blinkBluetoothConnectionDisplayer()
            sendData(data: "u")
            break
        case 2:
            print("pressed button = ", tag)
            toggleButtonEnabled(with: tag)
            blinkBluetoothConnectionDisplayer()
            sendData(data: "r")
            break
        case 3:
            print("pressed button = ", tag)
            toggleButtonEnabled(with: tag)
            blinkBluetoothConnectionDisplayer()
            sendData(data: "d")
            break
        case 4:
            print("pressed button = ", tag)
            toggleButtonEnabled(with: tag)
            blinkBluetoothConnectionDisplayer()
            sendData(data: "l")
            break
        case 5:
            print("pressed button = ", tag)
            toggleButtonEnabled(with: tag)
            blinkBluetoothConnectionDisplayer()
            sendData(data: "s")
            break
        default:
            toggleButtonEnabled(with: 5)
            blinkBluetoothConnectionDisplayer()
            sendData(data: "s")
        }
    }
    
    fileprivate func sendData(data: String) {
        let d = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        if let perDevice = hmsoftPeripheral {
            if let dat = d {
                if let c = self.characteristic {
                    perDevice.writeValue(dat, for: c, type: CBCharacteristicWriteType.withoutResponse)
                    print("enviou o dado => ", dat)
                }
            }
        }
    }
}


// MARK: - UI Setup
extension ViewController {
    
    private func initializeUIComponents() {
        setBackground()
        setUpConectionIndicatorView()
        setUpStopButton()
        setUpControlContainerView()
        setGlassCapImageView()
        setBluetoothSignalStrenthNoSignalImage()
        setSignalContainerView()
        setToggleConnectionView()
        setSignalContair()
    }
    
    private func setBackground() {
        if let image = UIImage(named: "background") {
            var imageView: UIImageView!
            imageView = UIImageView(frame: view.bounds)
            imageView.contentMode = UIView.ContentMode.scaleAspectFill
            imageView.clipsToBounds = true
            imageView.image = image
            imageView.center = view.center
            view.addSubview(imageView)
            self.view.sendSubviewToBack(imageView)
        }
    }
    
    private func setUpConectionIndicatorView() {
        conectionIndicator.layer.cornerRadius = 12
        conectionIndicator.backgroundColor = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)
    }
    
    private func setUpStopButton() {
        stopButton.setImage(UIImage(named: "pause-off"), for: .normal)
        stopButton.isEnabled = false
    }
    
    private func setUpControlContainerView() {
        controlContainerView.layer.cornerRadius = 180
        controlContainerView.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    private func setConnectionIndicatorOnUI() {
        conectionIndicator.backgroundColor = UIColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1)
    }
    
    private func setGlassCapImageView() {
        glassCapView.image = UIImage(named: "glass-cap")
    }
    
    private func setConnectionIndicatorOffUI() {
        conectionIndicator.backgroundColor = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)
    }
    
    private func setBluetoothSignalStrenthNoSignalImage() {
        bluetoothSignalStrenthImage.image = UIImage(named: "no-wifi")
    }
    
    private func setSignalContainerView() {
        signalContainerView.layer.cornerRadius = 25
    }
    
    private func setSignalContainerOffView() {
        signalContainerView.backgroundColor = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)
    }
    
    private func setSignalContainerOnView() {
        signalContainerView.backgroundColor = UIColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1)
    }
    
    private func setToggleConnectionView() {
        toggleConnectionView.layer.cornerRadius = 38.5
    }
    
    private func setSignalContair() {
        signalContainer.layer.cornerRadius = 38.5
    }
    
    private func positionSetSignalContair(_ connectionStatus: Bool) {

    }
    
    private func switchBluetoothSignalStrenthImage(signalStrenth signal: Int) {
        
        let noSignalImage       = UIImage(named: "no-wifi")
        let lowWifiImage        = UIImage(named: "low-wifi")
        let mediumWifiImage     = UIImage(named: "medium-wifi")
        let mediumHighWifiImage = UIImage(named: "wifi-medium-high")
        let highWifiImage       = UIImage(named: "high-wifi")
        
        
        switch signal {
        case -30...0:
            bluetoothSignalStrenthImage.image = highWifiImage
            break
        case -55...(-31):
            bluetoothSignalStrenthImage.image = mediumHighWifiImage
            break
        case -65...(-56):
            bluetoothSignalStrenthImage.image = mediumWifiImage
            break
        case -100...(-66):
            bluetoothSignalStrenthImage.image = lowWifiImage
            break
        default:
            bluetoothSignalStrenthImage.image = noSignalImage
        }
    }
    
    private func animateView(shouldGo forward: Bool) {
        let originalTransform = CGAffineTransform.identity
        let displacement = forward ? 70.0 : 0.0
        let scaledAndTranslatedTransform = originalTransform.translatedBy(x: CGFloat(displacement), y: 0)
        UIView.animate(withDuration: 0.7, animations: {
            self.signalContainer.transform = scaledAndTranslatedTransform;
        })
    }
    
    private func blinkBluetoothConnectionDisplayer() {
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: 0.12, repeats: false, block: { (_) in
                self.conectionIndicator.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 0, alpha: 1)
                Timer.scheduledTimer(withTimeInterval: 0.06, repeats: false, block: { (_) in
                    self.conectionIndicator.backgroundColor = UIColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1)
                    Timer.scheduledTimer(withTimeInterval: 0.12, repeats: false, block: { (_) in
                        self.conectionIndicator.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 0, alpha: 1)
                        Timer.scheduledTimer(withTimeInterval: 0.06, repeats: false, block: { (_) in
                            self.conectionIndicator.backgroundColor = UIColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1)
                        })
                    })
                })
            })
            
            
            
        }
    }
    
}
