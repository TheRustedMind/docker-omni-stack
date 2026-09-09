import { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";
import { open } from "@tauri-apps/plugin-dialog";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { HardDrive, FileUp, Loader2 } from "lucide-react";
import { VolumeInfo } from "../../lib/types";

interface VolumeManagerDialogProps {
  serviceName: string | null;
  isOpen: boolean;
  onClose: () => void;
}

export function VolumeManagerDialog({ serviceName, isOpen, onClose }: VolumeManagerDialogProps) {
  const [volumes, setVolumes] = useState<VolumeInfo[]>([]);
  const [selectedVolume, setSelectedVolume] = useState<string>("");
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [wipeVolume, setWipeVolume] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [uploadSuccess, setUploadSuccess] = useState<string | null>(null);
  const [volumeError, setVolumeError] = useState<string | null>(null);

  const [volumeMode, setVolumeMode] = useState<"upload" | "browse">("upload");
  const [browseFiles, setBrowseFiles] = useState<string[]>([]);
  const [loadingFiles, setLoadingFiles] = useState(false);

  useEffect(() => {
    if (isOpen && serviceName) {
      setVolumes([]);
      setSelectedVolume("");
      setSelectedFile(null);
      setWipeVolume(false);
      setUploadSuccess(null);
      setVolumeError(null);
      setUploading(true);
      
      invoke("get_service_volumes", { service: serviceName })
        .then((data: any) => {
          const vols = data as VolumeInfo[];
          setVolumes(vols);
          if (vols.length > 0) {
            setSelectedVolume(vols[0].name_or_source);
          }
        })
        .catch((e: any) => setVolumeError(e.toString()))
        .finally(() => setUploading(false));
    }
  }, [isOpen, serviceName]);

  useEffect(() => {
    if (volumeMode === "browse" && selectedVolume && volumes.length > 0) {
      setLoadingFiles(true);
      const vol = volumes.find(v => v.name_or_source === selectedVolume);
      if (vol) {
        invoke("list_volume_files", { mountType: vol.mount_type, nameOrSource: vol.name_or_source })
          .then((files: any) => setBrowseFiles(files))
          .catch(e => setVolumeError(e.toString()))
          .finally(() => setLoadingFiles(false));
      }
    }
  }, [volumeMode, selectedVolume, volumes]);

  const handleBrowseFile = async () => {
    try {
      const file = await open({ multiple: false, directory: false });
      if (file) {
        setSelectedFile(file as string);
        setUploadSuccess(null);
      }
    } catch (e: any) {
      console.error(e);
      setVolumeError("Failed to select file.");
    }
  };

  const handleUpload = async () => {
    if (!selectedVolume || !selectedFile || !serviceName) return;
    setUploading(true);
    setVolumeError(null);
    setUploadSuccess(null);
    
    const volInfo = volumes.find(v => v.name_or_source === selectedVolume);
    if (!volInfo) return;

    try {
      await invoke("upload_to_volume", {
        mountType: volInfo.mount_type,
        nameOrSource: volInfo.name_or_source,
        localPath: selectedFile,
        wipe: wipeVolume
      });
      setUploadSuccess("File uploaded successfully! If it was an archive, it has been extracted.");
      setSelectedFile(null);
      setWipeVolume(false);
    } catch (e: any) {
      setVolumeError(e.toString());
    } finally {
      setUploading(false);
    }
  };

  if (!isOpen || !serviceName) return null;

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-[500px] border-border shadow-2xl">
        <DialogHeader>
          <DialogTitle className="text-xl font-bold flex items-center gap-2">
            <HardDrive className="h-5 w-5" /> Storage Manager: {serviceName}
          </DialogTitle>
          <DialogDescription>
            Manage files or archives directly inside the service volume.
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-2">
           <div className="flex p-1 bg-muted rounded-lg">
              <Button variant={volumeMode === "upload" ? "default" : "ghost"} size="sm" className="w-1/2" onClick={() => setVolumeMode("upload")}>Upload</Button>
              <Button variant={volumeMode === "browse" ? "default" : "ghost"} size="sm" className="w-1/2" onClick={() => setVolumeMode("browse")}>Browse</Button>
           </div>
        </div>

        <div className="py-2 space-y-4">
          {volumeError && (
            <div className="p-3 bg-red-500/10 text-red-500 rounded-md text-sm font-medium border border-red-500/20">
              {volumeError}
            </div>
          )}
          
          {uploadSuccess && (
            <div className="p-3 bg-green-500/10 text-green-500 rounded-md text-sm font-medium border border-green-500/20">
              {uploadSuccess}
            </div>
          )}

          {volumes.length === 0 && !uploading ? (
            <div className="text-sm text-muted-foreground text-center py-4">
              No volumes found. Make sure the service has been initialized at least once.
            </div>
          ) : uploading && volumes.length === 0 ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="w-8 h-8 animate-spin text-primary" />
            </div>
          ) : (
            <>
              <div className="space-y-2">
                <Select value={selectedVolume} onValueChange={(v) => setSelectedVolume(v as string)}>
                  <SelectTrigger className="w-full cursor-pointer">
                    <SelectValue placeholder="Select a volume to manage" />
                  </SelectTrigger>
                  <SelectContent>
                    {volumes.map((v, i) => (
                      <SelectItem key={i} value={v.name_or_source} className="cursor-pointer">
                        {v.name_or_source.includes('/') || v.name_or_source.includes('\\') ? 'Host: ' : 'Docker: '} 
                        {v.name_or_source.split('/').pop()?.split('\\').pop() || v.name_or_source} 
                        <span className="text-muted-foreground ml-2 text-xs">({v.destination})</span>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {volumeMode === "upload" && (
                <div className="space-y-4 mt-4">
                  <div className="space-y-2">
                    <div className="flex items-center gap-3">
                      <Button variant="outline" onClick={handleBrowseFile} className="w-full cursor-pointer border-dashed border-2 bg-muted/20 hover:bg-muted/50">
                        <FileUp className="h-4 w-4 mr-2" /> Select File...
                      </Button>
                    </div>
                    {selectedFile && (
                      <div className="text-xs text-muted-foreground bg-muted/30 p-2 rounded truncate select-all">
                        Selected: {selectedFile}
                      </div>
                    )}
                    <p className="text-xs text-muted-foreground">
                      .zip and .tar files will be automatically extracted into the volume root.
                    </p>
                  </div>

                  <div className="flex items-center space-x-2 pt-2 border-t border-border">
                    <Checkbox 
                      id="wipe" 
                      checked={wipeVolume} 
                      onCheckedChange={(c) => setWipeVolume(c as boolean)} 
                      className="cursor-pointer"
                    />
                    <label htmlFor="wipe" className="text-sm font-medium leading-none cursor-pointer">
                      Wipe volume completely before uploading
                    </label>
                  </div>
                </div>
              )}

              {volumeMode === "browse" && (
                 <div className="mt-4 border border-border rounded-lg bg-muted/10 overflow-y-auto max-h-[250px] p-2">
                   {loadingFiles ? (
                      <div className="flex items-center justify-center py-8">
                        <Loader2 className="w-6 h-6 animate-spin text-primary" />
                      </div>
                   ) : browseFiles.length === 0 ? (
                      <div className="text-sm text-muted-foreground text-center py-4">Volume is empty.</div>
                   ) : (
                      <div className="space-y-1">
                         {browseFiles.map((file, idx) => (
                           <div key={idx} className="text-xs font-mono py-1 px-2 hover:bg-muted/30 rounded cursor-default select-all truncate">
                             {file}
                           </div>
                         ))}
                      </div>
                   )}
                 </div>
              )}
            </>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose} className="cursor-pointer" disabled={uploading}>
            Close
          </Button>
          {volumeMode === "upload" && (
            <Button 
              onClick={handleUpload} 
              disabled={uploading || !selectedFile || volumes.length === 0} 
              className="font-semibold shadow-sm cursor-pointer min-w-[120px]"
            >
              {uploading && selectedFile ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
              {uploading && selectedFile ? "Uploading..." : "Execute Upload"}
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
