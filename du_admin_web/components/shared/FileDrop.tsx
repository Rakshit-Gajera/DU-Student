'use client';

import { FileUp, Loader2 } from 'lucide-react';
import { useId, useRef, useState, type DragEvent } from 'react';
import { cn } from '@/lib/utils';

/** Drag-and-drop or click-to-browse file input. The API re-validates type and size. */
export function FileDrop({
  accept,
  hint,
  busy,
  onFile,
}: {
  accept: string;
  hint: string;
  busy?: boolean;
  onFile: (file: File) => void;
}) {
  const id = useId();
  const input = useRef<HTMLInputElement>(null);
  const [dragging, setDragging] = useState(false);

  function handleDrop(event: DragEvent<HTMLLabelElement>) {
    event.preventDefault();
    setDragging(false);
    const file = event.dataTransfer.files[0];
    if (file && !busy) onFile(file);
  }

  return (
    <label
      htmlFor={id}
      onDragOver={(e) => {
        e.preventDefault();
        setDragging(true);
      }}
      onDragLeave={() => setDragging(false)}
      onDrop={handleDrop}
      className={cn(
        'flex cursor-pointer flex-col items-center gap-1 rounded-md border border-dashed p-5 text-center text-sm transition-colors hover:bg-accent',
        dragging && 'border-primary bg-accent',
        busy && 'pointer-events-none opacity-60',
      )}
    >
      {busy ? (
        <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" aria-hidden />
      ) : (
        <FileUp className="h-5 w-5 text-muted-foreground" aria-hidden />
      )}
      <span className="font-medium">{busy ? 'Uploading' : 'Drop a file here, or click to browse'}</span>
      <span className="text-xs text-muted-foreground">{hint}</span>
      <input
        id={id}
        ref={input}
        type="file"
        accept={accept}
        className="sr-only"
        disabled={busy}
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) onFile(file);
          // Lets the same file be picked again after a failed upload.
          if (input.current) input.current.value = '';
        }}
      />
    </label>
  );
}
