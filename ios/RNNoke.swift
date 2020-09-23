import Foundation

@objc(RNNoke)
class RNNoke : RCTEventEmitter, NokeDeviceManagerDelegate {

    func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
        switch state {

        case .Discovered:

            sendEvent(withName: "onNokeDiscovered", body: [
                "name": noke.name,
                "mac": noke.mac,
                "hwVersion": noke.version,
                "lockState": noke.lockState,
                "connectionState": noke.connectionState
            ])
            break
        case .Connected:
            print(noke.session!)

            sendEvent(withName: "onNokeConnected", body: [
                "name": noke.name,
                "mac": noke.mac,
                "session": noke.session,
                "battery": noke.battery,
                "hwVersion": noke.version
            ])
            break
        case .Syncing:

            sendEvent(withName: "onNokeConnecting", body: ["name": noke.name, "mac": noke.mac, "hwVersion": noke.version])
            break
        case .Unlocked:

            sendEvent(withName: "onNokeUnlocked", body: ["name": noke.name, "mac": noke.mac])
            break
        case .Disconnected:
            NokeDeviceManager.shared().cacheUploadQueue()

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
        debugPrint(state)
        switch (state) {
        case NokeManagerBluetoothState.poweredOn:
            sendEvent(withName: "onBluetoothStatusChanged", body: ["code": 12, "message": "on"])
            break
        case NokeManagerBluetoothState.poweredOff:
            debugPrint("NOKE MANAGER OFF")
            sendEvent(withName: "onBluetoothStatusChanged", body: ["code": 10, "message": "off"])
            break
        default:
            debugPrint("NOKE MANAGER UNSUPPORTED")
            // FUTURE: handle other states
            break
        }
    }

    func nokeReadyForFirmwareUpdate(noke: NokeDevice) {
        // TODO: implement
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
        */
        let noke = NokeDevice.init(
            name: data["name"]! as String,
            mac: data["mac"]! as String
        )

        NokeDeviceManager.shared().addNoke(noke!)

        resolve(["status": true])
    }

    @objc func addNokeOfflineValues(
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
        _ mac: String,
        command: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        let daNoke: NokeDevice? = NokeDeviceManager.shared().nokeWithMac(mac)
        if(daNoke == nil) {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            reject("message", "unable to sendCommands, noke not found", error)
            return
        }
        daNoke?.sendCommands(command)

        resolve(["name": daNoke?.name, "mac": daNoke?.mac])
    }

    @objc func connect(
        _ mac: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        let daNoke: NokeDevice? = NokeDeviceManager.shared().nokeWithMac(mac)
        if(daNoke == nil) {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            reject("message", "unable to connect, noke not found", error)
            return
        }
        NokeDeviceManager.shared().connectToNokeDevice(daNoke!)
        resolve(["status": true])
    }

    @objc func disconnect(
        _ mac: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        let daNoke: NokeDevice? = NokeDeviceManager.shared().nokeWithMac(mac)
        if(daNoke == nil) {
            let error = NSError(domain: "", code: 200, userInfo: nil)
            reject("message", "unable to disconnect, noke not found", error)
            return
        }
        NokeDeviceManager.shared().disconnectNokeDevice(daNoke!)

        resolve(["status": true])
    }

    @objc func offlineUnlock(
        _ mac: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {
        let daNoke: NokeDevice? = NokeDeviceManager.shared().nokeWithMac(mac)
        var event: [String: Any] = [
            "name": daNoke?.name ?? String(),
            "mac": daNoke?.mac ?? String()
        ]
        if(daNoke == nil) {
            event["success"] = false
        } else {
            daNoke?.offlineUnlock()
            event["success"] = true
        }

        resolve(event)
    }

    @objc func removeAllNokes(
        _ resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {

        NokeDeviceManager.shared().removeAllNoke()

        resolve(["status": true])
    }

    @objc func removeNokeDevice(
        _ mac: String,
        resolver resolve: RCTPromiseResolveBlock,
        rejecter reject: RCTPromiseRejectBlock
        ) {

        NokeDeviceManager.shared().removeNoke(mac: mac)

        resolve(["status": true])
    }

    // @objc func isBluetoothEnabled(
    //     _ resolve: RCTPromiseResolveBlock,
    //     rejecter reject: RCTPromiseRejectBlock
    //     ) {

    //     resolve(["enabled": NokeDeviceManager.shared().isBluetoothEnabled()] as [String:Any])
    // }

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
            "onError",
            "onLocationStatusChanged"
        ]
    }
}
