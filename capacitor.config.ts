import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.mycompany.myproduct.myunimobileapp',
  appName: 'My MVP Product Unimobile',
  webDir: 'www',
  bundledWebRuntime: false,
  server: {
    cleartext: true,
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 0,
    },
  },
};
export default config;
