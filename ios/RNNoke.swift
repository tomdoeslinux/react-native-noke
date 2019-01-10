import Foundation

@objc(RNNoke)
class RNNoke : RCTEventEmitter, NokeDeviceManagerDelegate {
    var currentNoke: NokeDevice?

    func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
        switch state {

        case .nokeDeviceConnectionStateDiscovered:

            sendEvent(withName: "onNokeDiscovered", body: [
                "name": noke.name,
                "mac": noke.mac,
                "hwVersion": noke.version,
                "lockState": noke.lockState,
                "connectionState": noke.connectionState
            ])
            break
        case .nokeDeviceConnectionStateConnected:
            print(noke.session!)
            currentNoke = noke

            sendEvent(withName: "onNokeConnected", body: [
                "name": noke.name,
                "mac": noke.mac,
                "session": noke.session,
                "battery": noke.battery,
                "hwVersion": noke.version
            ])
            break
        case .nokeDeviceConnectionStateSyncing:

            sendEvent(withName: "onNokeConnecting", body: ["name": noke.name, "mac": noke.mac, "hwVersion": noke.version])
            break
        case .nokeDeviceConnectionStateUnlocked:

            sendEvent(withName: "onNokeUnlocked", body: ["name": noke.name, "mac": noke.mac])
            break
        case .nokeDeviceConnectionStateDisconnected:
            NokeDeviceManager.shared().cacheUploadQueue()
            currentNoke = nil

            sendEvent(withName: "onNokeDisconnected", body: ["name": noke.name, "mac": noke.mac])
            break
        default:

            sendEvent(withName: "onError", body: ["message": "unrecognized state"])
            break
        }
    }

    func nokeDeviceDidShutdown(noke: NokeDevice, isLocked: Bool, didTimeout: Bool) {
        sendEvent(withName: "onNokeShutdown", body: ["name": noke.name, "mac": noke.mac, "isLocked": isLocked, "didTimeout": didTimeout])
    }

    func nokeErrorDidOccur(error: NokeDeviceManagerError, message: String, noke: NokeDevice?) {
        debugPrint("NOKE MANAGER ON")
        var mac: String = "",
            name: String = ""
        if(noke != nil) {
            mac = (noke?.mac)!
            name = (noke?.name)!
        }
        sendEvent(withName: "onError", body: ["name": name, "mac": mac, "code": error, "message": message])
    }

    func didUploadData(result: Int, message: String) {
        // TODO
    }

    func bluetoothManagerDidUpdateState(state: NokeManagerBluetoothState) {
        var message: String = ""
        switch (state) {
        case NokeManagerBluetoothState.poweredOn:
            NokeDeviceManager.shared().startScanForNokeDevices()
            message = "on"
            break
        case NokeManagerBluetoothState.poweredOff:
            debugPrint("NOKE MANAGER OFF")
            message = "off"
            break
        default:
            debugPrint("NOKE MANAGER UNSUPPORTED")
            message = "unsupported"
            break
        }
        sendEvent(withName: "onBluetoothStatusChanged", body: ["code": 0, "message": message])
    }

    // Export constants to use in your native module
    override func constantsToExport() -> [AnyHashable : Any]! {
        return ["AUTHOR": "linh_the_human"]
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    @objc func startScan(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        NokeDeviceManager.shared().startScanForNokeDevices()

        resolve(["status": true])
    }

    @objc func stopScan(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        NokeDeviceManager.shared().stopScan()

        resolve(["status": true])
    }

    @objc func initiateNokeService(
        _ code: Int,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        NokeDeviceManager.shared().delegate = self

        var mode: NokeLibraryMode = NokeLibraryMode.SANDBOX

        switch code {
        case 0:
            mode = NokeLibraryMode.SANDBOX
            break
        case 1:
            mode = NokeLibraryMode.PRODUCTION
            break
        case 2:
            mode = NokeLibraryMode.DEVELOP
            break
        default:
            mode = NokeLibraryMode.SANDBOX
            break
        }

        NokeDeviceManager.shared().setLibraryMode(mode)

        resolve(["status": true])
    }

    @objc func setApiKey(
        _ key: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        NokeDeviceManager.shared().setAPIKey(key)

        resolve(["status": true])
    }

    @objc func addNokeDevice(
        _ data: Dictionary<String, String>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        /**
        * name: "Lock Name"
        * mac: "XX:XX:XX:XX:XX:XX"
        * key: "OFFLINE_KEY"
        * cmd: "OFFLINE_COMMAND"
        */
        let noke = NokeDevice.init(
            name: data["name"]! as String,
            mac: data["mac"]! as String
        )

        noke?.setOfflineValues(
            key: data["key"]! as String,
            command: data["cmd"]! as String
        )
        NokeDeviceManager.shared().addNoke(noke!)

        resolve(["status": true])
    }

    @objc func sendCommands(
        _ command: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
    ) {
        if(currentNoke == nil) {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            reject("message", "currentNoke is null", error)
            return
        }
        currentNoke?.sendCommands(command)

        resolve(["name": currentNoke?.name, "mac": currentNoke?.mac])
    }

    @objc func connect(
        _ data: Dictionary<String, String>,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        var daNoke: NokeDevice? = NokeDeviceManager.shared().nokeWithMac(data["mac"]!)
        NokeDeviceManager.shared().connectToNokeDevice(daNoke!)
        resolve(["status": true])
    }

    @objc func disconnect(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        if(currentNoke == nil) {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            reject("message", "currentNoke is null", error)
            return
        }
        NokeDeviceManager.shared().disconnectNokeDevice(currentNoke!)

        resolve(["status": true])
    }

    @objc func offlineUnlock(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        var event: [String: Any] = [
            "name": currentNoke?.name ?? String(),
            "mac": currentNoke?.mac ?? String()
        ]
        if(currentNoke == nil) {
            event["success"] = false
        } else {
            currentNoke?.offlineUnlock()
            event["success"] = true
        }

        resolve(event)
    }

    @objc func removeAllNokes(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {

        NokeDeviceManager.shared().removeAllNoke()

        resolve([
            "status": true
            ])
    }

    @objc func removeNokeDevice(
        _ mac: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {

        NokeDeviceManager.shared().removeNoke(mac: mac)

        resolve([
            "status": true
            ])
    }

    override func supportedEvents() -> [String]! {
        return [
            "onServiceConnected",
            "onServiceDisconnected",
            "onNokeDiscovered",
            "onNokeConnecting",
            "onNokeConnected",
            "onNokeSyncing",
            "onNokeUnlocked",
            "onNokeDisconnected",
            "onNokeShutdown",
            "onBluetoothStatusChanged",
            "onError"
        ]
    }
}
