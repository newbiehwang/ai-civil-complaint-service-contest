import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { ScenarioFlowTestScreen } from "./src/screens/ScenarioFlowTestScreen";

export default function App() {
  return (
    <SafeAreaProvider>
      <StatusBar style="dark" />
      <ScenarioFlowTestScreen />
    </SafeAreaProvider>
  );
}
