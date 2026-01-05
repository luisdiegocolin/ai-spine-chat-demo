/**
 * File type detection utilities for chat messages
 */

export type FileType = 'pdf' | 'image' | 'other'

/**
 * Detect file type from URL
 */
export function detectFileType(url: string): FileType {
  const lowerUrl = url.toLowerCase()

  // Check for images
  if (lowerUrl.match(/\.(jpg|jpeg|png|gif|webp|svg)$/)) {
    return 'image'
  }

  // Check for PDFs (either by extension or by generated file pattern)
  if (lowerUrl.includes('.pdf') || lowerUrl.includes('/api/v1/files/f_')) {
    return 'pdf'
  }

  return 'other'
}

/**
 * Check if URL is a generated file from the AI Spine API
 */
export function isGeneratedFile(url: string): boolean {
  // Generated files follow pattern: /api/v1/files/f_xxxxx or full URL with domain
  return url.includes('/api/v1/files/f_') || url.includes('/files/f_')
}
