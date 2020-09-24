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
  on: onEvent,
  once: onEventOnce,
  off: offEvent,
  offlineUnlock: RNNoke.offlineUnlock,
  sendCommands: RNNoke.sendCommands,
  addNokeDevice: RNNoke.addNokeDevice,
  addNokeOfflineValues: RNNoke.addNokeOfflineValues, 
  removeAllNokes: RNNoke.removeAllNokes,
  removeNokeDevice: RNNoke.removeNokeDevice,
  startScan: RNNoke.startScan,
  stopScan: RNNoke.stopScan,
  disconnect: RNNoke.disconnect,
  connect: RNNoke.connect,
  fromNokeEvents,
  getEventListeners,
  isBluetoothEnabled: RNNoke.isBluetoothEnabled,

  /*** Only android methods*/
  setBluetoothDelayDefault: RNNoke.setBluetoothDelayDefault,
  setBluetoothDelayBackgroundDefault: RNNoke.setBluetoothDelayBackgroundDefault,
  setBluetoothScanDuration: RNNoke.setBluetoothScanDuration,
};
