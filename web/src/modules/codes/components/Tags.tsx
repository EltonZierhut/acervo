import { Link } from 'react-router-dom'

export function Tags({ tags }: { tags: string[] }) {
  if (!tags.length) return null
  return (
    <div className="tags">
      {tags.map((tag) => (
        <Link key={tag} to={`/codigos?tag=${encodeURIComponent(tag)}`} className="tag">
          #{tag}
        </Link>
      ))}
    </div>
  )
}
