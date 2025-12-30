export function TypingIndicator() {
  return (
    <div className="flex items-center space-x-2 py-4">
      <div className="flex space-x-1">
        <div
          className="w-2 h-2 bg-white/60 rounded-full animate-bounce"
          style={{ animationDelay: '-0.3s' }}
        />
        <div
          className="w-2 h-2 bg-white/60 rounded-full animate-bounce"
          style={{ animationDelay: '-0.15s' }}
        />
        <div className="w-2 h-2 bg-white/60 rounded-full animate-bounce" />
      </div>
    </div>
  )
}
