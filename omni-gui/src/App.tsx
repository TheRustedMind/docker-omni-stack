import { useState } from "react";
import "./index.css";
import { Loader2 } from "lucide-react";

import { useStackContext } from "./context/StackContext";
import { TopNav } from "./components/TopNav";
import { OfflineScreen } from "./components/OfflineScreen";
import { ServiceCard } from "./components/ServiceCard";
import { RestartDialog } from "./components/dialogs/RestartDialog";
import { EnvConfigDialog } from "./components/dialogs/EnvConfigDialog";
import { VolumeManagerDialog } from "./components/dialogs/VolumeManagerDialog";

export default function App() {
  const {
    services,
    statuses,
    loading,
    isGlobalStopping,
    isGlobalStarting
  } = useStackContext();

  const [restartService, setRestartService] = useState<string | null>(null);
  const [envService, setEnvService] = useState<string | null>(null);
  const [volumeService, setVolumeService] = useState<string | null>(null);

  const anyServiceRunning = Object.values(statuses).some(status => status.startsWith("Up") || status.startsWith("Running") || status.startsWith("Toggling"));
  const isOfflineScreen = (!anyServiceRunning && !isGlobalStopping) || isGlobalStarting;

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center text-foreground transition-colors duration-300">
        <div className="flex flex-col items-center">
           <Loader2 className="w-12 h-12 text-primary animate-spin mb-4" />
           <p className="text-lg font-medium text-muted-foreground">Booting Dashboard...</p>
        </div>
      </div>
    );
  }

  if (isOfflineScreen) {
    return <OfflineScreen onOpenEnv={setEnvService} />;
  }

  const coreApps = ["caddy", "authentik"];
  const otherApps = Object.keys(services)
    .filter((name) => !coreApps.includes(name))
    .sort((nameA, nameB) => nameA.localeCompare(nameB));

  return (
    <div className="min-h-screen bg-background text-foreground transition-colors duration-300 relative">
      
      {isGlobalStopping && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-background/80 backdrop-blur-sm">
          <div className="flex flex-col items-center">
             <Loader2 className="w-16 h-16 text-primary animate-spin mb-4" />
             <h2 className="text-2xl font-bold tracking-tight">Stopping Stack...</h2>
             <p className="text-muted-foreground mt-2">Gracefully shutting down containers.</p>
          </div>
        </div>
      )}

      <TopNav />

      <div className="max-w-7xl mx-auto px-6 py-8 z-30">
        <div className="mb-12">
          <div className="mb-6">
            <h2 className="text-2xl font-bold tracking-tight">Core Infrastructure</h2>
            <p className="text-muted-foreground">Essential routing and security services.</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {coreApps.map((name) => (
              <ServiceCard 
                key={name} 
                name={name} 
                onOpenEnv={setEnvService} 
                onOpenVolume={setVolumeService} 
                onOpenRestart={setRestartService} 
              />
            ))}
          </div>
        </div>

        <div>
          <div className="mb-6 border-t border-border pt-8">
            <h2 className="text-2xl font-bold tracking-tight">Applications</h2>
            <p className="text-muted-foreground">Your configured stack services.</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {otherApps.map((name) => (
              <ServiceCard 
                key={name} 
                name={name} 
                onOpenEnv={setEnvService} 
                onOpenVolume={setVolumeService} 
                onOpenRestart={setRestartService} 
              />
            ))}
          </div>
        </div>
      </div>

      <RestartDialog 
        serviceName={restartService} 
        isOpen={!!restartService} 
        onClose={() => setRestartService(null)} 
      />
      <EnvConfigDialog 
        serviceName={envService} 
        isOpen={!!envService} 
        onClose={() => setEnvService(null)} 
      />
      <VolumeManagerDialog 
        serviceName={volumeService} 
        isOpen={!!volumeService} 
        onClose={() => setVolumeService(null)} 
      />
    </div>
  );
}
