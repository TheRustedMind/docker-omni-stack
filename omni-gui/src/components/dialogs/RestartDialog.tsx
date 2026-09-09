import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { RefreshCw, Loader2 } from "lucide-react";
import { useStackContext } from "../../context/StackContext";

interface RestartDialogProps {
  serviceName: string | null;
  isOpen: boolean;
  onClose: () => void;
}

export function RestartDialog({ serviceName, isOpen, onClose }: RestartDialogProps) {
  const { services, statuses, executeDirectRestart } = useStackContext();
  const [dependentServices, setDependentServices] = useState<{name: string, checked: boolean, isUp: boolean}[]>([]);
  const [restarting, setRestarting] = useState(false);

  useEffect(() => {
    if (isOpen && serviceName) {
      const deps = Object.entries(services)
        .filter(([_, svc]) => svc.DependsOn?.includes(serviceName))
        .map(([name]) => name);
        
      if (deps.length > 0) {
        setDependentServices(deps.map(name => {
          const isUp = statuses[name]?.startsWith("Up") || statuses[name]?.startsWith("Running");
          return { name, checked: isUp, isUp };
        }));
      } else {
        // If no dependents, execute direct and close immediately
        executeDirectRestart(serviceName, []);
        onClose();
      }
    }
  }, [isOpen, serviceName, services, statuses, executeDirectRestart, onClose]);

  const executeRestart = async () => {
    if (!serviceName) return;
    setRestarting(true);
    const toRestart = dependentServices.filter(s => s.checked).map(s => s.name);
    await executeDirectRestart(serviceName, toRestart);
    setRestarting(false);
    onClose();
  };

  if (!isOpen || !serviceName || dependentServices.length === 0) return null;

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[400px] border-border shadow-2xl">
        <DialogHeader>
          <DialogTitle className="text-xl font-bold flex items-center gap-2">
            <RefreshCw className="h-5 w-5" /> Restart {serviceName}
          </DialogTitle>
          <DialogDescription>
            Select dependent services to restart alongside {serviceName}.
          </DialogDescription>
        </DialogHeader>
        <div className="py-4 space-y-4">
           <div className="flex items-center justify-between">
              <Button variant="ghost" size="sm" onClick={() => setDependentServices(dependentServices.map(s => ({...s, checked: s.isUp})))}>Select All Active</Button>
              <Button variant="ghost" size="sm" onClick={() => setDependentServices(dependentServices.map(s => ({...s, checked: false})))}>Deselect All</Button>
           </div>
           <div className="space-y-3">
             {dependentServices.map(dep => (
               <div key={dep.name} className="flex items-center space-x-3">
                 <Checkbox 
                   id={`dep-${dep.name}`} 
                   checked={dep.checked} 
                   disabled={!dep.isUp}
                   onCheckedChange={(c) => setDependentServices(dependentServices.map(s => s.name === dep.name ? {...s, checked: !!c} : s))}
                 />
                 <label htmlFor={`dep-${dep.name}`} className={`text-sm font-medium ${!dep.isUp ? 'text-muted-foreground' : ''}`}>
                   {dep.name} {!dep.isUp && "(Stopped)"}
                 </label>
               </div>
             ))}
           </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={executeRestart} disabled={restarting} className="font-semibold">
            {restarting ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
            {restarting ? "Restarting..." : "Restart Selected"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
