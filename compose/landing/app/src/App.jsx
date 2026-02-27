import projects from "./data/projects";

const env = import.meta.env;

const name = env.VITE_NAME || "Ilia Ivanov";
const title = env.VITE_TITLE || "Python Software Developer";
const bio =
  env.VITE_BIO ||
  "Backend developer with 8+ years of Python experience. Specializing in high-load APIs, billing systems, analytics platforms, and ML pipelines.";
const email = env.VITE_EMAIL || "";
const telegram = env.VITE_TELEGRAM || "";
const linkedin = env.VITE_LINKEDIN || "";

const githubProfiles = ["ku113p", "digitalscyther"];

const techStack = {
  Languages: ["Python", "Go", "Rust", "JavaScript"],
  "Frameworks & Libraries": [
    "FastAPI",
    "Flask",
    "Django",
    "Celery",
    "LangChain",
    "LangGraph",
  ],
  "Databases & Storage": [
    "PostgreSQL",
    "MySQL",
    "SQLite",
    "MongoDB",
    "Redis",
    "ClickHouse",
  ],
  Infrastructure: [
    "Docker",
    "Kubernetes",
    "Traefik",
    "Nginx",
    "GitHub Actions",
  ],
  Monitoring: ["Prometheus", "Grafana", "Datadog"],
};

function MailIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect width="20" height="16" x="2" y="4" rx="2" />
      <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
    </svg>
  );
}

function TelegramIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
      <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z" />
    </svg>
  );
}

function GitHubIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
    </svg>
  );
}

function LinkedInIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
      <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
    </svg>
  );
}

function ExternalLinkIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
      <polyline points="15 3 21 3 21 9" />
      <line x1="10" y1="14" x2="21" y2="3" />
    </svg>
  );
}

function ContactLinks() {
  const links = [];

  if (email) {
    links.push(
      <a key="email" href={`mailto:${email}`} className="contact-link" title="Email">
        <MailIcon />
        <span>{email}</span>
      </a>,
    );
  }

  if (telegram) {
    links.push(
      <a key="tg" href={`https://t.me/${telegram}`} className="contact-link" target="_blank" rel="noopener noreferrer" title="Telegram">
        <TelegramIcon />
        <span>@{telegram}</span>
      </a>,
    );
  }

  githubProfiles.forEach((profile) => {
    links.push(
      <a key={`gh-${profile}`} href={`https://github.com/${profile}`} className="contact-link" target="_blank" rel="noopener noreferrer" title="GitHub">
        <GitHubIcon />
        <span>{profile}</span>
      </a>,
    );
  });

  if (linkedin) {
    links.push(
      <a key="li" href={`https://linkedin.com/in/${linkedin}`} className="contact-link" target="_blank" rel="noopener noreferrer" title="LinkedIn">
        <LinkedInIcon />
        <span>LinkedIn</span>
      </a>,
    );
  }

  return <div className="contact-links">{links}</div>;
}

function ProjectCard({ project }) {
  return (
    <div className="project-card">
      <h3 className="project-name">{project.name}</h3>
      <p className="project-description">{project.description}</p>
      <div className="project-tech">
        {project.tech.map((t) => (
          <span key={t} className="tech-badge">
            {t}
          </span>
        ))}
      </div>
      {project.links.length > 0 && (
        <div className="project-links">
          {project.links.map((link) => (
            <a key={link.url} href={link.url} className="project-link" target="_blank" rel="noopener noreferrer">
              <span>{link.label}</span>
              <ExternalLinkIcon />
            </a>
          ))}
        </div>
      )}
    </div>
  );
}

function TechStackSection() {
  return (
    <section className="section">
      <h2 className="section-title">Tech Stack</h2>
      <div className="tech-stack">
        {Object.entries(techStack).map(([category, items]) => (
          <div key={category} className="tech-category">
            <h4 className="tech-category-name">{category}</h4>
            <div className="tech-badges">
              {items.map((item) => (
                <span key={item} className="tech-badge">
                  {item}
                </span>
              ))}
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}

export default function App() {
  return (
    <div className="app">
      <header className="hero">
        <div className="hero-content">
          <h1 className="hero-name">{name}</h1>
          <p className="hero-title">{title}</p>
          <p className="hero-bio">{bio}</p>
          <ContactLinks />
        </div>
      </header>

      <main className="container">
        <section className="section">
          <h2 className="section-title">Projects</h2>
          <div className="projects-grid">
            {projects.map((project) => (
              <ProjectCard key={project.name} project={project} />
            ))}
          </div>
        </section>

        <TechStackSection />
      </main>
    </div>
  );
}
