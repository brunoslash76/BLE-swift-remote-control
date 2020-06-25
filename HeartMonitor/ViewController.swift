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
    
    private var centralManager: CBCentralManager!
    private var hmsoftPeripheral: CBPeripheral!
    private var cha: CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        initializeUIComponents()
    }
    
    @IBAction func onPressButtonSend(_ sender: UIButton) {
        print(sender.tag)
        switchButtonTag(with: sender.tag)
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
        case .poweredOn:
          print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [hmSoftBLE])
        default:
            print("central.state is I really dont know")
        }
        
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
        hmsoftPeripheral.discoverServices(nil)
        setConnectionIndicatorOnUI()
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
                self.cha = characteristic
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
            self.cha = characteristic
            break
        default:
            print("Default", characteristic)
        }
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
            sendData(data: "u")
            break
        case 2:
            print("pressed button = ", tag)
            toggleButtonEnabled(with: tag)
            sendData(data: "d")
            break
        case 3:
            print("pressed button = ", tag)
            toggleButtonEnabled(with: tag)
            sendData(data: "r")
            break
        case 4:
            print("pressed button = ", tag)
            toggleButtonEnabled(with: tag)
            sendData(data: "l")
            break
        case 5:
            print("pressed button = ", tag)
            toggleButtonEnabled(with: tag)
            sendData(data: "s")
            break
        default:
            toggleButtonEnabled(with: 5)
            sendData(data: "s")
        }
    }
    
    fileprivate func sendData(data: String) {
        let d = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        if let perDevice = hmsoftPeripheral {
            if let dat = d {
                if let c = self.cha {
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
        controlContainerView.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.8)
    }
    
    private func setConnectionIndicatorOnUI() {
        conectionIndicator.backgroundColor = UIColor(displayP3Red: 0, green: 1, blue: 0, alpha: 1)
    }
    
    private func setGlassCapImageView() {
        glassCapView.image = UIImage(named: "glass-cap")
    }
}
