import { Button, Badge, LayerCard, Tooltip } from "@cloudflare/kumo";
import {
  Heart,
  GithubLogo,
  Download,
  Lightning,
  Eye,
  ArrowsClockwise,
  CurrencyDollar,
  ChatCircle,
  Sparkle,
} from "@phosphor-icons/react/dist/ssr";

export default function Home() {
  return (
    <main className="flex-1">
      {/* Hero */}
      <section className="relative min-h-screen flex flex-col justify-center px-6 py-20 overflow-hidden">
        {/* Background glow */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[600px] bg-[radial-gradient(ellipse,rgba(255,107,107,0.08)_0%,transparent_70%)] pointer-events-none" />

        <div className="max-w-5xl mx-auto w-full relative z-10">
          <Badge className="mb-8" variant="neutral">
            <span className="flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-[#FF6B6B] animate-pulse" />
              v0.1.1 — Now Available
            </span>
          </Badge>

          <h1 className="text-5xl md:text-7xl font-serif leading-tight tracking-tight mb-6 max-w-3xl">
            Your code&apos;s{" "}
            <span className="italic bg-gradient-to-r from-[#FF6B6B] to-[#FFB347] bg-clip-text text-transparent">
              heartbeat
            </span>
            ,<br />
            always in sight.
          </h1>

          <p className="text-lg text-[#8a8a9a] max-w-xl mb-10 leading-relaxed">
            DevPulse is a macOS menu bar app that monitors your opencode sessions in real-time. See agent states, token usage, and subagent activity at a glance.
          </p>

          <div className="flex gap-4 flex-wrap">
            <a href="https://github.com/albertjiayou0423/devpulse/releases/latest">
              <Button variant="primary" size="lg" icon={<Download weight="bold" />}>
                Download DMG
              </Button>
            </a>
            <a href="https://github.com/albertjiayou0423/devpulse">
              <Button variant="secondary" size="lg" icon={<GithubLogo weight="bold" />}>
                View on GitHub
              </Button>
            </a>
          </div>

          {/* Mockup */}
          <div className="mt-16">
            <div className="w-full max-w-2xl mx-auto h-10 bg-[#12121a] rounded-xl border border-[#2a2a36] flex items-center px-4 gap-3 shadow-2xl">
              <div className="w-2 h-2 rounded-full bg-[#34C759] shadow-[0_0_8px_#34C759] animate-pulse" />
              <span className="text-xs font-mono text-[#8a8a9a]">main session</span>
              <div className="ml-auto flex gap-1.5">
                <div className="w-1.5 h-1.5 rounded-full bg-[#AF52DE] shadow-[0_0_6px_#AF52DE]" />
                <div className="w-1.5 h-1.5 rounded-full bg-[#32ADE6] shadow-[0_0_6px_#32ADE6]" />
                <div className="w-1.5 h-1.5 rounded-full bg-[#34C759] shadow-[0_0_6px_#34C759]" />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="px-6 py-24">
        <div className="max-w-5xl mx-auto">
          <p className="text-[#FF6B6B] font-mono uppercase tracking-widest mb-4 text-sm">
            Features
          </p>
          <h2 className="text-3xl md:text-4xl font-serif mb-4 max-w-2xl">
            Everything you need to monitor your AI workflow
          </h2>
          <p className="text-[#8a8a9a] mb-12 max-w-xl">
            DevPulse integrates seamlessly with opencode, providing real-time insights without interrupting your flow.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <FeatureCard
              icon={<Lightning weight="bold" className="text-2xl" />}
              title="Real-time Monitoring"
              desc="Watch your opencode sessions as they run. Status updates instantly in your menu bar."
            />
            <FeatureCard
              icon={<Eye weight="bold" className="text-2xl" />}
              title="Status Indicators"
              desc="Visual feedback for working, thinking, idle, compacting, and error states with color-coded dots."
            />
            <FeatureCard
              icon={<ArrowsClockwise weight="bold" className="text-2xl" />}
              title="Subagent Tracking"
              desc="See all child sessions with hover-to-inspect details. Know exactly what your agents are doing."
            />
            <FeatureCard
              icon={<CurrencyDollar weight="bold" className="text-2xl" />}
              title="Token Usage"
              desc="Track context window consumption at a glance. Never be surprised by token costs again."
            />
            <FeatureCard
              icon={<ChatCircle weight="bold" className="text-2xl" />}
              title="Question Handling"
              desc="Respond to opencode questions directly from the menu bar without switching contexts."
            />
            <FeatureCard
              icon={<Sparkle weight="bold" className="text-2xl" />}
              title="Glass-morphism HUD"
              desc="Beautiful translucent interface that matches your macOS aesthetic. Minimal and non-intrusive."
            />
          </div>
        </div>
      </section>

      {/* Status Colors */}
      <section className="px-6 py-24">
        <div className="max-w-5xl mx-auto">
          <LayerCard className="p-10 md:p-16">
            <p className="text-[#FF6B6B] font-mono uppercase tracking-widest mb-4 text-sm">
              Status System
            </p>
            <h2 className="text-3xl md:text-4xl font-serif mb-4">
              Know what&apos;s happening at a glance
            </h2>
            <p className="text-[#8a8a9a] mb-10 max-w-xl">
              Every state has a distinct color, making it easy to understand your session&apos;s status without reading text.
            </p>

            <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
              <StatusItem color="#34C759" name="Idle" />
              <StatusItem color="#AF52DE" name="Working" />
              <StatusItem color="#32ADE6" name="Thinking" />
              <StatusItem color="#FF9500" name="Compacting" />
              <StatusItem color="#FF3B30" name="Error" />
            </div>
          </LayerCard>
        </div>
      </section>

      {/* Installation */}
      <section className="px-6 py-24">
        <div className="max-w-5xl mx-auto">
          <p className="text-[#FF6B6B] font-mono uppercase tracking-widest mb-4 text-sm">
            Installation
          </p>
          <h2 className="text-3xl md:text-4xl font-serif mb-4">
            Up and running in seconds
          </h2>
          <p className="text-[#8a8a9a] mb-12 max-w-xl">
            Download, drag to Applications, and you&apos;re done. No configuration needed.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <InstallStep number={1} title="Download" desc="Grab the latest DevPulse.dmg from GitHub Releases." />
            <InstallStep number={2} title="Install" desc="Open the DMG and drag DevPulse to your Applications folder." />
            <InstallStep number={3} title="Launch" desc="Start DevPulse and make sure opencode is running. That's it!" />
          </div>
        </div>
      </section>

      {/* Requirements */}
      <section className="px-6 py-24">
        <div className="max-w-5xl mx-auto">
          <p className="text-[#FF6B6B] font-mono uppercase tracking-widest mb-4 text-sm">
            Requirements
          </p>
          <h2 className="text-3xl md:text-4xl font-serif mb-10">
            What you&apos;ll need
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-2xl">
            <LayerCard className="p-6">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-[rgba(255,107,107,0.1)] flex items-center justify-center text-2xl">
                  💻
                </div>
                <div>
                  <h3 className="font-semibold mb-1">macOS 14.0+</h3>
                  <p className="text-sm text-[#8a8a9a]">DevPulse requires macOS Sonoma or later.</p>
                </div>
              </div>
            </LayerCard>
            <LayerCard className="p-6">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-[rgba(255,107,107,0.1)] flex items-center justify-center text-2xl">
                  ⚡
                </div>
                <div>
                  <h3 className="font-semibold mb-1">opencode</h3>
                  <p className="text-sm text-[#8a8a9a]">
                    Make sure{" "}
                    <a href="https://github.com/opencode-ai/opencode" className="text-[#FF6B6B] hover:underline">
                      opencode
                    </a>{" "}
                    is installed and running.
                  </p>
                </div>
              </div>
            </LayerCard>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-[#2a2a36] py-12 px-6">
        <div className="max-w-5xl mx-auto text-center">
          <div className="flex justify-center gap-8 mb-6 flex-wrap">
            <a href="https://github.com/albertjiayou0423/devpulse" className="text-[#8a8a9a] hover:text-[#FF6B6B] transition-colors text-sm">
              GitHub
            </a>
            <a href="https://github.com/albertjiayou0423/devpulse/releases" className="text-[#8a8a9a] hover:text-[#FF6B6B] transition-colors text-sm">
              Releases
            </a>
            <a href="https://github.com/albertjiayou0423/devpulse/wiki" className="text-[#8a8a9a] hover:text-[#FF6B6B] transition-colors text-sm">
              Wiki
            </a>
            <a href="https://www.patreon.com/cw/huo_sai" className="text-[#8a8a9a] hover:text-[#FF6B6B] transition-colors text-sm flex items-center gap-1">
              <Heart weight="fill" className="text-[#FF6B6B]" size={14} />
              Support on Patreon
            </a>
          </div>
          <p className="text-xs font-mono text-[#5a5a6a] tracking-wide">
            DevPulse · MIT License · Built with ❤️ for developers
          </p>
        </div>
      </footer>
    </main>
  );
}

function FeatureCard({ icon, title, desc }: { icon: React.ReactNode; title: string; desc: string }) {
  return (
    <LayerCard className="p-8 hover:border-[#FF6B6B] transition-colors group">
      <div className="w-12 h-12 rounded-xl bg-[rgba(255,107,107,0.1)] flex items-center justify-center text-[#FF6B6B] mb-5">
        {icon}
      </div>
      <h3 className="font-semibold text-lg mb-2">{title}</h3>
      <p className="text-sm text-[#8a8a9a] leading-relaxed">{desc}</p>
    </LayerCard>
  );
}

function StatusItem({ color, name }: { color: string; name: string }) {
  return (
    <div className="flex items-center gap-3 p-4 bg-[#0a0a0f] rounded-xl border border-[#2a2a36]">
      <Tooltip content={`${name} state`}>
        <div
          className="w-2.5 h-2.5 rounded-full flex-shrink-0"
          style={{ background: color, boxShadow: `0 0 8px ${color}` }}
        />
      </Tooltip>
      <span className="text-xs font-mono uppercase tracking-wider">{name}</span>
    </div>
  );
}

function InstallStep({ number, title, desc }: { number: number; title: string; desc: string }) {
  return (
    <div className="relative p-8 bg-[#12121a] rounded-2xl border border-[#2a2a36]">
      <div className="absolute -top-4 left-6 w-8 h-8 bg-[#FF6B6B] rounded-full flex items-center justify-center text-sm font-bold text-white font-mono">
        {number}
      </div>
      <h3 className="font-semibold text-lg mt-2 mb-2">{title}</h3>
      <p className="text-sm text-[#8a8a9a] leading-relaxed">{desc}</p>
    </div>
  );
}
