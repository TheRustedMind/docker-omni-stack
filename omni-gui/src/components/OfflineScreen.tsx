import { Button } from "@/components/ui/button";
import { Loader2, Play, Settings, Sun, Moon } from "lucide-react";
import { useStackContext } from "../context/StackContext";
import { MockupSlider } from "./MockupSlider";

interface OfflineScreenProps {
  onOpenEnv: (service: string) => void;
}

export function OfflineScreen({ onOpenEnv }: OfflineScreenProps) {
  const {
    isGlobalStarting,
    isStartingDocker,
    darkMode,
    setDarkMode,
    isDockerRunning,
    handleStartDocker,
    useDockerVolumes,
    setUseDockerVolumes,
    startStack
  } = useStackContext();

  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center text-foreground p-8 transition-colors duration-300 relative">
      {(isGlobalStarting || isStartingDocker) && (
        <div className="absolute inset-0 z-50 flex items-center justify-center bg-background/80 backdrop-blur-sm">
          <div className="flex flex-col items-center">
             <Loader2 className="w-16 h-16 text-primary animate-spin mb-4" />
             <h2 className="text-2xl font-bold tracking-tight">
               {isStartingDocker ? "Starting Docker Engine..." : "Starting Infrastructure..."}
             </h2>
             <p className="text-muted-foreground mt-2">
               {isStartingDocker ? "Waiting for Docker daemon to become available." : "Spinning up containers and resolving networks."}
             </p>
          </div>
        </div>
      )}

      <div className="absolute top-6 right-8 z-40 flex items-center space-x-2">
          <Button variant="ghost" size="icon" onClick={() => onOpenEnv("global")} className="rounded-full cursor-pointer">
            <Settings className="h-5 w-5" />
          </Button>
          <Button variant="ghost" size="icon" onClick={() => setDarkMode(!darkMode)} className="rounded-full cursor-pointer">
             {darkMode ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
          </Button>
      </div>
      <div className="max-w-md w-full text-center space-y-8 z-40">
         <div className="space-y-3">
           <h1 className="text-5xl font-extrabold tracking-tight text-foreground">Omni Stack</h1>
           <p className="text-lg text-muted-foreground font-medium">
             {isDockerRunning === false ? "Docker Engine is offline." : "All systems are currently standing by."}
           </p>
         </div>
         
         {isDockerRunning === false ? (
           <div className="p-6 bg-red-500/10 border border-red-500/20 rounded-2xl flex flex-col items-center">
             <p className="text-red-500 dark:text-red-400 font-medium mb-6 text-sm">You must start the Docker Engine to initialize the environment.</p>
             <Button onClick={handleStartDocker} disabled={isStartingDocker} variant="outline" className="w-full h-12 font-semibold">
               <Play className="mr-2 h-4 w-4" />
               Start Docker Engine
             </Button>
           </div>
         ) : (
           <>
             <div className="flex items-center justify-between p-5 bg-muted/20 rounded-2xl border border-border shadow-sm text-left backdrop-blur-sm">
               <div className="pr-4">
                 <h3 className="font-semibold text-foreground tracking-tight">Storage Isolation</h3>
                 <p className="text-sm text-muted-foreground leading-relaxed mt-1">Persist application data inside managed Docker volumes instead of local host directories.</p>
               </div>
               <MockupSlider checked={useDockerVolumes} disabled={false} onChange={setUseDockerVolumes} />
             </div>
  
             <Button size="lg" onClick={startStack} disabled={isDockerRunning === null} className="w-full text-lg h-14 rounded-xl shadow-md hover:shadow-lg transition-all font-semibold tracking-wide cursor-pointer">
               <Play className="mr-2 h-5 w-5 fill-current" /> Initialize Environment
             </Button>
           </>
         )}
      </div>
    </div>
  );
}
