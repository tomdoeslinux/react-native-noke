import {
  NativeModules
} from 'react-native';
import {
  fromNokeEvents,
  onEvent,
  onEventOnce,
  offEvent,
  getEventListeners
} from './events';

const { RNNoke } = NativeModules;

export default {
  initiateNokeService: RNNoke.initiateNokeService,
  setApiKey: RNNoke.setApiKey,
  setBluetoothDelayDefault: RNNoke.setBluetoothDelayDefault,
  setBluetoothDelayBackgroundDefault: RNNoke.setBluetoothDelayBackgroundDefault,
  setBluetoothScanDuration: RNNoke.setBluetoothScanDuration,
  on: onEvent,
  once: onEventOnce,
  off: offEvent,
  offlineUnlock: RNNoke.offlineUnlock,
  sendCommands: RNNoke.sendCommands,
  addNokeDevice(data) {
    return RNNoke.addNokeDevice(data);
  },
  removeAllNokes: RNNoke.removeAllNokes,
  removeNokeDevice: RNNoke.removeNokeDevice,
  startScan: RNNoke.startScan,
  stopScan: RNNoke.stopScan,
  disconnect: RNNoke.disconnect,
  connect: RNNoke.connect,
  getDeviceInfo: RNNoke.getDeviceInfo,
  setOfflineData: RNNoke.setOfflineData,
  addNokeDeviceOnce: RNNoke.addNokeDeviceOnce,
  fromNokeEvents,
  getEventListeners,
  isBluetoothEnabled: RNNoke.isBluetoothEnabled,
  AUTHOR: RNNoke.AUTHOR
};
