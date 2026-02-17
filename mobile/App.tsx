import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { ScenarioFlowTestScreen } from "./src/screens/ScenarioFlowTestScreen";
import { CaseProvider } from "./src/store/caseContext";

export default function App() {
  return (
    <SafeAreaProvider>
      <CaseProvider>
        <StatusBar style="dark" />
        <ScenarioFlowTestScreen />
      </CaseProvider>
    </SafeAreaProvider>
  );
}
