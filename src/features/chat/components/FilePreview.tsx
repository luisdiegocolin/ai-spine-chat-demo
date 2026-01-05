import { FileText } from 'lucide-react'
import { detectFileType } from '../utils/fileDetector'

interface FilePreviewProps {
  url: string
  children?: React.ReactNode
}

export function FilePreview({ url, children }: FilePreviewProps) {
  const fileType = detectFileType(url)

  // PDF preview - show as card with icon
  if (fileType === 'pdf') {
    return (
      <a
        href={url}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-flex items-center gap-2 bg-white/10 hover:bg-white/20 border border-white/20 hover:border-white/40 rounded-lg transition-all duration-300 no-underline"
        style={{ padding: '0.5rem 0.75rem' }}
      >
        <div className="flex items-center justify-center w-8 h-8 bg-[#d8ffb3]/20 rounded">
          <FileText className="w-4 h-4 text-[#d8ffb3]" />
        </div>
        <div className="flex flex-col">
          <span className="text-white font-medium text-xs">
            {children || 'PDF Document'}
          </span>
          <span className="text-white/60" style={{ fontSize: '10px' }}>Click to open</span>
        </div>
      </a>
    )
  }

  // Image preview - show inline
  if (fileType === 'image') {
    return (
      <a href={url} target="_blank" rel="noopener noreferrer" className="block">
        <img
          src={url}
          alt={typeof children === 'string' ? children : 'Generated image'}
          className="max-w-full rounded-lg border border-white/20 hover:border-white/40 transition-colors"
          style={{ maxHeight: '400px', objectFit: 'contain' }}
        />
      </a>
    )
  }

  // Other links - normal link styling
  return (
    <a
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      className="text-[#d8ffb3] hover:text-[#bfffd1] underline transition-colors"
    >
      {children}
    </a>
  )
}
