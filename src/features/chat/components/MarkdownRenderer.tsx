import ReactMarkdown from 'react-markdown'
import { FilePreview } from './FilePreview'
import { isGeneratedFile } from '../utils/fileDetector'

interface MarkdownRendererProps {
  content: string
}

export function MarkdownRenderer({ content }: MarkdownRendererProps) {
  // Color theme (white on dark glassmorphic background)
  const textColor = 'text-white/90'
  const strongColor = 'text-white'
  const mutedColor = 'text-white/80'

  return (
    <ReactMarkdown
      components={{
        // Paragraphs
        p: ({ ...props }) => (
          <p className={`text-sm leading-relaxed ${textColor} mb-2 last:mb-0 wrap-break-words`} {...props} />
        ),
        // Bold text
        strong: ({ ...props }) => (
          <strong className={`font-bold ${strongColor}`} {...props} />
        ),
        // Italic text
        em: ({ ...props }) => (
          <em className={`italic ${textColor}`} {...props} />
        ),
        // Unordered lists
        ul: ({ ...props }) => (
          <ul className={`list-disc pl-5 space-y-1 text-sm ${textColor} mb-2`} {...props} />
        ),
        // Ordered lists
        ol: ({ ...props }) => (
          <ol className={`list-decimal pl-5 space-y-1 text-sm ${textColor} mb-2`} {...props} />
        ),
        // List items
        li: ({ ...props }) => (
          <li className={`${textColor} leading-relaxed`} {...props} />
        ),
        // Headings
        h1: ({ ...props }) => (
          <h1 className={`text-lg font-bold ${strongColor} mb-2`} {...props} />
        ),
        h2: ({ ...props }) => (
          <h2 className={`text-base font-bold ${strongColor} mb-2`} {...props} />
        ),
        h3: ({ ...props }) => (
          <h3 className={`text-sm font-semibold ${strongColor} mb-2`} {...props} />
        ),
        // Links
        a: ({ href, children, ...props }) => {
          // Check if this is a generated file from AI Spine
          if (href && isGeneratedFile(href)) {
            return <FilePreview url={href}>{children}</FilePreview>
          }
          // Normal links
          return (
            <a href={href} className="text-[#d8ffb3] hover:text-[#bfffd1] underline transition-colors" {...props}>
              {children}
            </a>
          )
        },
        // Blockquotes
        blockquote: ({ ...props }) => (
          <blockquote className={`border-l-2 border-white/30 pl-3 italic ${mutedColor} my-2`} {...props} />
        ),
        // Code blocks (multiline)
        pre: ({ ...props }) => (
          <pre className="bg-white/10 p-3 rounded-lg overflow-x-auto text-sm font-mono my-2 border border-white/10" {...props} />
        ),
        // Inline code
        code: ({ ...props }) => (
          <code className="bg-white/10 px-1.5 py-0.5 rounded text-sm font-mono border border-white/10" {...props} />
        ),
      }}
    >
      {content}
    </ReactMarkdown>
  )
}
