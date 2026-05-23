import 'react-native-gesture-handler';
import { registerRootComponent } from 'expo';
import App from './App';

// registerRootComponent envolve App em AppRegistry.registerComponent('main', ...)
// e funciona tanto no Expo Go quanto em build standalone.
registerRootComponent(App);
