"use client";

import { useMemo, useState } from "react";
import {
  Activity,
  Award,
  Bell,
  CalendarDays,
  Check,
  ChevronLeft,
  ChevronRight,
  CircleCheckBig,
  CircleUserRound,
  Clock3,
  Home,
  ListFilter,
  Map,
  MapPin,
  Minus,
  Play,
  Plus,
  RotateCcw,
  Search,
  Send,
  SlidersHorizontal,
  Sparkles,
  Swords,
  Target,
  Trophy,
  UserRoundPlus,
  UsersRound,
  X,
} from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Toaster } from "@/components/ui/sonner";

type Section = "home" | "play" | "matches" | "courts" | "profile";
type Player = {
  name: string;
  initials: string;
  skill: string;
  distance: string;
  record: string;
  availability: string;
  compatibility: number;
  tone: "dark" | "lime" | "soft" | "clay";
};

const navItems = [
  { id: "home" as const, label: "Home", icon: Home },
  { id: "play" as const, label: "Play", icon: Play },
  { id: "matches" as const, label: "Matches", icon: CalendarDays },
  { id: "courts" as const, label: "Courts", icon: Map },
  { id: "profile" as const, label: "Profile", icon: CircleUserRound },
];

const players: Player[] = [
  { name: "Jamie Cruz", initials: "JC", skill: "Intermediate", distance: "2.4 km away", record: "18–12", availability: "Available Saturday", compatibility: 94, tone: "clay" },
  { name: "Miguel Santos", initials: "MS", skill: "Intermediate", distance: "4.1 km away", record: "21–16", availability: "Available Thursday", compatibility: 89, tone: "soft" },
  { name: "Sofia Lim", initials: "SL", skill: "Intermediate", distance: "3.2 km away", record: "17–10", availability: "Available Sunday", compatibility: 86, tone: "lime" },
  { name: "Alex Reyes", initials: "AR", skill: "Advanced", distance: "5.8 km away", record: "32–14", availability: "Available Saturday", compatibility: 82, tone: "dark" },
];

const courts = [
  { name: "BGC Tennis Club", distance: "1.8 km", surface: "Hard", setting: "Outdoor", x: 58, y: 42 },
  { name: "Makati Sports Club", distance: "4.2 km", surface: "Hard", setting: "Indoor / Outdoor", x: 29, y: 63 },
  { name: "PhilSports Tennis Courts", distance: "6.7 km", surface: "Hard", setting: "Outdoor", x: 76, y: 24 },
];

function BrandMark() {
  return (
    <div className="brand-mark" aria-hidden="true">
      <span />
      <span />
    </div>
  );
}

function Avatar({
  initials,
  tone = "dark",
  size = "md",
}: {
  initials: string;
  tone?: "dark" | "lime" | "soft" | "clay";
  size?: "sm" | "md" | "lg" | "xl";
}) {
  return (
    <span className={`avatar avatar-${tone} avatar-${size}`} aria-hidden="true">
      {initials}
    </span>
  );
}

export default function RallyUpApp() {
  const [section, setSection] = useState<Section>("home");
  const [immersive, setImmersive] = useState(false);

  const navigate = (next: Section) => {
    setImmersive(false);
    setSection(next);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  return (
    <div className={`app-canvas ${immersive ? "is-immersive" : ""}`}>
      <aside className="desktop-sidebar" aria-label="Primary navigation">
        <div className="desktop-brand"><BrandMark /><span>RallyUp</span></div>
        <nav className="desktop-nav">
          {navItems.map(({ id, label, icon: Icon }) => (
            <button key={id} className={section === id ? "active" : ""} onClick={() => navigate(id)}>
              <Icon />
              <span>{label}</span>
            </button>
          ))}
        </nav>
        <div className="sidebar-card">
          <Sparkles />
          <strong>3-match streak</strong>
          <span>Keep the momentum going.</span>
        </div>
        <div className="sidebar-profile">
          <Avatar initials="ER" size="sm" />
          <div><strong>Eric Rotaquio</strong><span>Intermediate</span></div>
        </div>
      </aside>

      <div className="app-shell">
        {!immersive && <header className="mobile-topbar">
          <button className="mobile-brand" onClick={() => navigate("home")} aria-label="RallyUp home">
            <BrandMark /><span>RallyUp</span>
          </button>
          <button className="icon-button" aria-label="Notifications" onClick={() => toast.info("You have one new match invite from Sofia.")}>
            <Bell /><i />
          </button>
        </header>}

        <main id="top" className="main-content">
          {section === "home" && <HomeScreen onNavigate={navigate} />}
          {section === "play" && <PlayScreen />}
          {section === "matches" && <MatchesScreen onImmersiveChange={setImmersive} />}
          {section === "courts" && <CourtsScreen />}
          {section === "profile" && <ProfileScreen />}
        </main>

        {!immersive && <nav className="mobile-tabbar" aria-label="Primary navigation">
          {navItems.map(({ id, label, icon: Icon }) => (
            <button key={id} className={section === id ? "active" : ""} onClick={() => navigate(id)}>
              <Icon />
              <span>{label}</span>
            </button>
          ))}
        </nav>}
      </div>
      <Toaster position="top-center" richColors />
    </div>
  );
}

function HomeScreen({ onNavigate }: { onNavigate: (section: Section) => void }) {
  return (
    <section className="screen home-screen">
      <div className="home-header">
        <div>
          <p className="eyebrow">Saturday, September 19</p>
          <h1>Good morning, Eric</h1>
        </div>
        <Avatar initials="ER" tone="lime" size="lg" />
      </div>

      <article className="next-match-card">
        <div className="match-card-topline">
          <span className="live-label"><i />Next match</span>
          <span>In 7 days</span>
        </div>
        <div className="versus-row">
          <div className="player-identity"><Avatar initials="ER" tone="soft" size="lg" /><strong>Eric</strong></div>
          <div className="versus-separator"><span>VS</span><b>Singles</b></div>
          <div className="player-identity"><Avatar initials="JC" tone="clay" size="lg" /><strong>Jamie</strong></div>
        </div>
        <div className="match-meta">
          <span><CalendarDays />Sat, Sep 26</span>
          <span><Clock3 />7:00 PM</span>
          <span><MapPin />BGC Tennis Club</span>
        </div>
        <Button className="lime-button" size="lg" onClick={() => onNavigate("matches")}>View match <ChevronRight /></Button>
      </article>

      <section className="quick-actions" aria-labelledby="quick-actions-title">
        <div className="section-heading"><h2 id="quick-actions-title">Quick actions</h2></div>
        <div className="quick-action-grid">
          <button onClick={() => onNavigate("play")}><span><Search /></span><strong>Find player</strong><small>Nearby matches</small></button>
          <button onClick={() => onNavigate("matches")}><span><Swords /></span><strong>Start match</strong><small>Live scoring</small></button>
          <button onClick={() => onNavigate("courts")}><span><MapPin /></span><strong>Find court</strong><small>Explore venues</small></button>
        </div>
      </section>

      <div className="dashboard-grid">
        <article className="record-card">
          <div className="section-heading"><h2>Your record</h2><button onClick={() => onNavigate("profile")}>Details <ChevronRight /></button></div>
          <div className="record-stats">
            <div><strong>15</strong><span>Wins</span></div>
            <div><strong>9</strong><span>Losses</span></div>
            <div><strong>63%</strong><span>Win rate</span></div>
            <div className="streak"><Trophy /><strong>3</strong><span>Win streak</span></div>
          </div>
        </article>

        <section className="suggested-section">
          <div className="section-heading"><h2>Suggested players</h2><button onClick={() => onNavigate("play")}>See all <ChevronRight /></button></div>
          <div className="player-list">
            {players.slice(0, 2).map((player) => (
              <button className="player-row" key={player.name} onClick={() => onNavigate("play")}>
                <Avatar initials={player.initials} tone={player.tone} />
                <span className="player-copy"><strong>{player.name}</strong><small>{player.skill} · {player.distance}</small></span>
                <span className="compatibility"><strong>{player.compatibility}%</strong><small>Match</small></span>
                <ChevronRight />
              </button>
            ))}
          </div>
        </section>
      </div>

      <article className="recent-match">
        <div><span className="result-icon"><Target /></span><div><small>Recent match</small><strong>Won vs Miguel Santos</strong><span>6–4, 3–6, 6–2</span></div></div>
        <span className="win-pill">Won</span>
      </article>
    </section>
  );
}

function ScreenHeader({ eyebrow, title, action }: { eyebrow?: string; title: string; action?: React.ReactNode }) {
  return (
    <header className="screen-header">
      <div>{eyebrow && <p className="eyebrow">{eyebrow}</p>}<h1>{title}</h1></div>
      {action}
    </header>
  );
}

function PlayScreen() {
  const [query, setQuery] = useState("");
  const [activeFilter, setActiveFilter] = useState("All");
  const [profile, setProfile] = useState<Player | null>(null);
  const [invite, setInvite] = useState<Player | null>(null);

  const visiblePlayers = useMemo(() => players.filter((player) => {
    const matchesQuery = player.name.toLowerCase().includes(query.toLowerCase());
    const matchesFilter = activeFilter === "All" || activeFilter === "Intermediate"
      ? activeFilter === "All" || player.skill === "Intermediate"
      : activeFilter === "Under 5 km"
        ? Number(player.distance.split(" ")[0]) < 5
        : true;
    return matchesQuery && matchesFilter;
  }), [query, activeFilter]);

  const openInvite = (player: Player) => {
    setProfile(null);
    setInvite(player);
  };

  return (
    <section className="screen play-screen">
      <ScreenHeader eyebrow="Compatible players nearby" title="Find players" action={<button className="round-action" aria-label="Filters"><SlidersHorizontal /></button>} />

      <div className="search-box"><Search /><Input aria-label="Search players" placeholder="Search players" value={query} onChange={(event) => setQuery(event.target.value)} /></div>
      <div className="filter-row" aria-label="Player filters">
        {["All", "Under 5 km", "Intermediate", "This weekend"].map((filter) => (
          <button key={filter} className={activeFilter === filter ? "active" : ""} onClick={() => setActiveFilter(filter)}>{filter}</button>
        ))}
      </div>

      <div className="match-recommendation">
        <Sparkles />
        <div><strong>Top matches</strong><span>Ranked by skill, distance, and availability.</span></div>
      </div>

      <div className="player-card-grid">
        {visiblePlayers.map((player) => (
          <article className="player-card" key={player.name}>
            <div className="player-card-top">
              <Avatar initials={player.initials} tone={player.tone} size="xl" />
              <span className="match-score"><strong>{player.compatibility}%</strong><small>Match</small></span>
            </div>
            <div className="player-card-title"><div><h2>{player.name}</h2><p>{player.skill} · {player.distance}</p></div><span className="availability-dot"><i />Available</span></div>
            <dl className="player-facts">
              <div><dt>Record</dt><dd>{player.record}</dd></div>
              <div><dt>Plays</dt><dd>Singles</dd></div>
              <div><dt>Next open</dt><dd>{player.availability.replace("Available ", "")}</dd></div>
            </dl>
            <div className="match-reasons">
              <span><Check />Similar skill</span><span><Check />Nearby</span><span><Check />Matching availability</span>
            </div>
            <div className="card-actions">
              <Button variant="outline" onClick={() => setProfile(player)}>View profile</Button>
              <Button className="lime-button compact" onClick={() => setInvite(player)}><UserRoundPlus />Invite</Button>
            </div>
          </article>
        ))}
      </div>

      {visiblePlayers.length === 0 && <div className="empty-state"><UsersRound /><h2>No players found</h2><p>Try a broader name or filter.</p><Button variant="outline" onClick={() => { setQuery(""); setActiveFilter("All"); }}>Clear filters</Button></div>}

      <PlayerProfileSheet player={profile} onClose={() => setProfile(null)} onInvite={openInvite} />
      <InviteSheet player={invite} onClose={() => setInvite(null)} />
    </section>
  );
}

function PlayerProfileSheet({ player, onClose, onInvite }: { player: Player | null; onClose: () => void; onInvite: (player: Player) => void }) {
  return (
    <Sheet open={Boolean(player)} onOpenChange={(open) => !open && onClose()}>
      <SheetContent side="bottom" className="profile-sheet" aria-describedby="profile-description">
        {player && <>
          <SheetHeader className="sheet-heading">
            <div className="sheet-grabber" aria-hidden="true" />
            <SheetTitle>Player profile</SheetTitle>
            <SheetDescription id="profile-description">Review compatibility before sending an invite.</SheetDescription>
          </SheetHeader>
          <div className="sheet-scroll">
            <div className="profile-hero">
              <Avatar initials={player.initials} tone={player.tone} size="xl" />
              <div><h2>{player.name}</h2><p>{player.skill} · {player.distance}</p><span className="availability-dot"><i />{player.availability}</span></div>
            </div>
            <div className="profile-stats">
              <div><strong>{player.record.split("–")[0]}</strong><span>Wins</span></div>
              <div><strong>{player.record.split("–")[1]}</strong><span>Losses</span></div>
              <div><strong>60%</strong><span>Win rate</span></div>
            </div>
            <section className="profile-block"><h3>Playing style</h3><div className="tag-row"><span>Right-handed</span><span>Singles</span><span>Baseline</span></div></section>
            <section className="profile-block"><h3>Availability</h3><div className="availability-list"><span>Tuesday evening</span><span>Thursday evening</span><span>Saturday morning</span></div></section>
            <section className="profile-block"><h3>Recent matches</h3><div className="compact-results"><span><b>Win</b> vs Mia Santos <em>6–3, 6–4</em></span><span><b className="loss">Loss</b> vs David Tan <em>4–6, 5–7</em></span></div></section>
            <section className="profile-block"><h3>Head-to-head with Eric</h3><div className="head-to-head-mini"><span><b>Eric</b><strong>2</strong></span><i>VS</i><span><b>{player.name.split(" ")[0]}</b><strong>2</strong></span></div></section>
          </div>
          <div className="sheet-sticky-action"><Button className="lime-button" onClick={() => onInvite(player)}>Invite to play <ChevronRight /></Button></div>
        </>}
      </SheetContent>
    </Sheet>
  );
}

function InviteSheet({ player, onClose }: { player: Player | null; onClose: () => void }) {
  const sendInvite = () => {
    toast.success(`Invite sent to ${player?.name}`, { description: "Saturday, September 26 at 7:00 PM" });
    onClose();
  };
  return (
    <Sheet open={Boolean(player)} onOpenChange={(open) => !open && onClose()}>
      <SheetContent side="bottom" className="invite-sheet" aria-describedby="invite-description">
        {player && <>
          <SheetHeader className="sheet-heading">
            <div className="sheet-grabber" aria-hidden="true" />
            <SheetTitle>Invite to play</SheetTitle>
            <SheetDescription id="invite-description">Choose the match details for {player.name}.</SheetDescription>
          </SheetHeader>
          <div className="invite-player"><Avatar initials={player.initials} tone={player.tone} /><div><strong>{player.name}</strong><span>{player.compatibility}% match · {player.distance}</span></div></div>
          <div className="form-list">
            <label><span>Match type</span><select defaultValue="Singles"><option>Singles</option><option>Doubles</option></select></label>
            <label><span>Date</span><input type="text" defaultValue="September 26" /></label>
            <label><span>Time</span><input type="text" defaultValue="7:00 PM" /></label>
            <label><span>Court</span><select defaultValue="BGC Tennis Club"><option>BGC Tennis Club</option><option>Makati Sports Club</option><option>PhilSports Tennis Courts</option></select></label>
            <label><span>Format</span><select defaultValue="Best of 3"><option>Best of 3</option><option>One set</option><option>Pro set</option></select></label>
            <label className="notes-field"><span>Notes</span><textarea placeholder="Add a note" rows={3} /></label>
          </div>
          <div className="sheet-sticky-action"><Button className="lime-button" onClick={sendInvite}><Send />Send invite</Button></div>
        </>}
      </SheetContent>
    </Sheet>
  );
}

type MatchMode = "list" | "details" | "live" | "complete" | "summary";
type Score = { ericPoints: number; jamiePoints: number; ericGames: number; jamieGames: number };

function MatchesScreen({ onImmersiveChange }: { onImmersiveChange: (immersive: boolean) => void }) {
  const [mode, setMode] = useState<MatchMode>("list");
  const changeMode = (next: MatchMode) => {
    setMode(next);
    onImmersiveChange(next !== "list");
    window.scrollTo({ top: 0, behavior: "smooth" });
  };
  if (mode === "details") return <MatchDetails onBack={() => changeMode("list")} onStart={() => changeMode("live")} />;
  if (mode === "live") return <LiveScoring onBack={() => changeMode("details")} onFinish={() => changeMode("complete")} />;
  if (mode === "complete") return <MatchComplete onSummary={() => changeMode("summary")} onDone={() => changeMode("list")} />;
  if (mode === "summary") return <MatchSummary onBack={() => changeMode("complete")} />;

  return (
    <section className="screen matches-screen">
      <ScreenHeader eyebrow="Schedule and results" title="Matches" />
      <Tabs defaultValue="upcoming" className="matches-tabs">
        <TabsList className="segmented-tabs">
          <TabsTrigger value="upcoming">Upcoming</TabsTrigger>
          <TabsTrigger value="invites">Invites <span className="count-badge">1</span></TabsTrigger>
          <TabsTrigger value="history">History</TabsTrigger>
        </TabsList>
        <TabsContent value="upcoming">
          <div className="date-label">Saturday, September 26</div>
          <button className="upcoming-match-card" onClick={() => changeMode("details")}>
            <div className="upcoming-time"><strong>7:00</strong><span>PM</span></div>
            <div className="upcoming-players"><div><Avatar initials="JC" tone="clay" /><span><strong>Jamie Cruz</strong><small>Singles · Best of 3</small></span></div><span><MapPin />BGC Tennis Club</span></div>
            <ChevronRight />
          </button>
          <div className="date-label">Friday, October 2</div>
          <button className="upcoming-match-card">
            <div className="upcoming-time"><strong>8:00</strong><span>PM</span></div>
            <div className="upcoming-players"><div><Avatar initials="MS" tone="soft" /><span><strong>Miguel Santos</strong><small>Singles · Best of 3</small></span></div><span><MapPin />Makati Sports Club</span></div>
            <ChevronRight />
          </button>
          <section className="invite-preview"><div><Avatar initials="SL" tone="lime" /><span><strong>Sofia invited you to play</strong><small>Sunday, 6:00 PM · PhilSports</small></span></div><Button variant="outline" onClick={() => toast.info("Invite details opened")}>View invite</Button></section>
        </TabsContent>
        <TabsContent value="invites">
          <section className="invite-card"><Avatar initials="SL" tone="lime" size="lg" /><div><h2>Sofia Lim</h2><p>Sunday, September 27 · 6:00 PM</p><p>PhilSports Tennis Courts · Singles</p></div><div className="invite-actions"><Button variant="outline" onClick={() => toast("Invite declined")}>Decline</Button><Button className="lime-button compact" onClick={() => toast.success("Match accepted")}>Accept</Button></div></section>
        </TabsContent>
        <TabsContent value="history">
          <div className="history-list">
            {[["Miguel Santos", "Sep 19", "Won", "6–4, 3–6, 6–2"], ["Jamie Cruz", "Aug 15", "Won", "6–4, 4–6, 6–3"], ["Alex Reyes", "Jul 28", "Lost", "3–6, 5–7"]].map(([name, date, result, score]) => <div key={date}><span className={result === "Won" ? "history-result win" : "history-result"}>{result[0]}</span><span><strong>{name}</strong><small>{date} · {score}</small></span><ChevronRight /></div>)}
          </div>
        </TabsContent>
      </Tabs>
    </section>
  );
}

function BackHeader({ title, onBack, status }: { title: string; onBack: () => void; status?: string }) {
  return <header className="back-header"><button onClick={onBack} aria-label="Go back"><ChevronLeft /></button><strong>{title}</strong>{status ? <span>{status}</span> : <i />}</header>;
}

function MatchDetails({ onBack, onStart }: { onBack: () => void; onStart: () => void }) {
  return (
    <section className="screen detail-screen">
      <BackHeader title="Match details" onBack={onBack} />
      <div className="detail-versus">
        <div><Avatar initials="ER" tone="soft" size="xl" /><strong>Eric Rotaquio</strong></div><span>VS<small>Singles</small></span><div><Avatar initials="JC" tone="clay" size="xl" /><strong>Jamie Cruz</strong></div>
      </div>
      <div className="detail-layout">
        <section className="detail-list">
          <div><CalendarDays /><span><small>Date</small><strong>September 26</strong></span></div>
          <div><Clock3 /><span><small>Time</small><strong>7:00 PM</strong></span></div>
          <div><MapPin /><span><small>Court</small><strong>BGC Tennis Club</strong></span></div>
          <div><Swords /><span><small>Format</small><strong>Best of 3</strong></span></div>
        </section>
        <div>
          <section className="head-to-head-card"><h2>Head-to-head</h2><div><span><small>Eric</small><strong>2</strong></span><i>VS</i><span><small>Jamie</small><strong>2</strong></span></div></section>
          <section className="previous-meeting"><small>Previous meeting · August 15</small><strong>Eric won</strong><span>6–4, 4–6, 6–3</span></section>
        </div>
      </div>
      <div className="page-action"><Button className="lime-button" onClick={onStart}>Start match <ChevronRight /></Button></div>
    </section>
  );
}

function pointLabel(me: number, opponent: number) {
  if (me >= 3 && opponent >= 3) {
    if (me === opponent) return "40";
    return me > opponent ? "AD" : "40";
  }
  return ["0", "15", "30", "40"][Math.min(me, 3)];
}

function LiveScoring({ onBack, onFinish }: { onBack: () => void; onFinish: () => void }) {
  const [score, setScore] = useState<Score>({ ericPoints: 2, jamiePoints: 1, ericGames: 4, jamieGames: 3 });
  const [history, setHistory] = useState<Score[]>([]);
  const deuce = score.ericPoints >= 3 && score.jamiePoints >= 3 && score.ericPoints === score.jamiePoints;

  const addPoint = (player: "eric" | "jamie") => {
    setHistory((items) => [...items, score]);
    const next = { ...score };
    if (player === "eric") next.ericPoints += 1; else next.jamiePoints += 1;
    if (next.ericPoints >= 4 && next.ericPoints - next.jamiePoints >= 2) {
      next.ericGames += 1; next.ericPoints = 0; next.jamiePoints = 0;
      toast.success("Game Eric");
    } else if (next.jamiePoints >= 4 && next.jamiePoints - next.ericPoints >= 2) {
      next.jamieGames += 1; next.ericPoints = 0; next.jamiePoints = 0;
      toast.success("Game Jamie");
    }
    setScore(next);
  };
  const undo = () => {
    const previous = history.at(-1);
    if (!previous) return;
    setScore(previous);
    setHistory((items) => items.slice(0, -1));
  };

  return (
    <section className="screen scoring-screen">
      <BackHeader title="RallyUp Match" onBack={onBack} status="Live" />
      <div className="scoring-title"><span>SET 1</span><small>Singles · Best of 3</small></div>
      <section className="games-board">
        <div><span><i className="server-dot" />Eric Rotaquio</span><strong>{score.ericGames}</strong></div>
        <div><span>Jamie Cruz</span><strong>{score.jamieGames}</strong></div>
      </section>
      <section className="points-board">
        <p>Current game</p>
        <div><span><small>Eric</small><strong>{pointLabel(score.ericPoints, score.jamiePoints)}</strong></span><i /><span><small>Jamie</small><strong>{pointLabel(score.jamiePoints, score.ericPoints)}</strong></span></div>
        {deuce && <div className="deuce-banner">DEUCE</div>}
      </section>
      <div className="point-controls">
        <Button onClick={() => addPoint("eric")} className="point-button primary"><Plus />Eric point</Button>
        <Button onClick={() => addPoint("jamie")} className="point-button secondary"><Plus />Jamie point</Button>
      </div>
      <div className="scoring-footer">
        <Button variant="ghost" onClick={undo} disabled={!history.length}><RotateCcw />Undo</Button>
        <Button variant="outline" onClick={onFinish}>Finish match</Button>
      </div>
    </section>
  );
}

function MatchComplete({ onSummary, onDone }: { onSummary: () => void; onDone: () => void }) {
  return (
    <section className="screen complete-screen">
      <CircleCheckBig />
      <p className="eyebrow">Match complete</p>
      <h1>Great match.</h1>
      <div className="complete-versus"><div><Avatar initials="ER" tone="lime" size="xl" /><strong>Eric Rotaquio</strong></div><span>def.</span><div><Avatar initials="JC" tone="clay" size="xl" /><strong>Jamie Cruz</strong></div></div>
      <div className="final-score"><strong>6–4</strong><strong>3–6</strong><strong>6–2</strong></div>
      <div className="complete-meta"><span><Clock3 />1h 42m</span><span><MapPin />BGC Tennis Club</span></div>
      <div className="complete-actions"><Button className="lime-button" onClick={onSummary}>View match summary</Button><Button variant="ghost" onClick={onDone}>Done</Button></div>
    </section>
  );
}

function MatchSummary({ onBack }: { onBack: () => void }) {
  return (
    <section className="screen summary-screen">
      <BackHeader title="Match summary" onBack={onBack} />
      <div className="summary-result"><span>WIN</span><strong>6–4&nbsp;&nbsp; 3–6&nbsp;&nbsp; 6–2</strong></div>
      <div className="summary-grid">{[["Duration", "1h 42m"], ["Sets", "2–1"], ["Games", "15–12"], ["Court", "BGC Tennis Club"]].map(([label, value]) => <div key={label}><small>{label}</small><strong>{value}</strong></div>)}</div>
      <section className="head-to-head-summary"><h2>Head-to-head</h2><div><span><Avatar initials="ER" tone="soft" /><b>Eric</b><strong>3</strong></span><span><Avatar initials="JC" tone="clay" /><b>Jamie</b><strong>2</strong></span></div></section>
    </section>
  );
}

function CourtsScreen() {
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState(courts[0].name);
  const visibleCourts = courts.filter((court) => court.name.toLowerCase().includes(query.toLowerCase()));
  return (
    <section className="screen courts-screen">
      <ScreenHeader eyebrow="Metro Manila" title="Courts" action={<button className="round-action" aria-label="Recenter map"><Target /></button>} />
      <div className="map-search search-box"><Search /><Input aria-label="Search courts" placeholder="Search courts" value={query} onChange={(event) => setQuery(event.target.value)} /></div>
      <div className="court-layout">
        <div className="map-canvas" aria-label="Demo map of nearby tennis courts">
          <div className="map-road road-a" /><div className="map-road road-b" /><div className="map-road road-c" />
          <span className="map-area area-a">Makati</span><span className="map-area area-b">BGC</span><span className="map-area area-c">Pasig</span>
          {courts.map((court) => <button key={court.name} className={selected === court.name ? "map-pin active" : "map-pin"} style={{ left: `${court.x}%`, top: `${court.y}%` }} onClick={() => setSelected(court.name)} aria-label={court.name}><MapPin /></button>)}
        </div>
        <section className="nearby-courts"><div className="sheet-grabber" aria-hidden="true" /><div className="section-heading"><h2>Nearby courts</h2><span>{visibleCourts.length} nearby</span></div>
          <div className="court-list">{visibleCourts.map((court) => <button key={court.name} className={selected === court.name ? "active" : ""} onClick={() => setSelected(court.name)}><span className="court-thumb"><MapPinnedIcon /></span><span><strong>{court.name}</strong><small><MapPin />{court.distance}</small><em>{court.surface} · {court.setting}</em></span><ChevronRight /></button>)}</div>
        </section>
      </div>
    </section>
  );
}

function MapPinnedIcon() {
  return <><span className="court-line" /><span className="court-line horizontal" /></>;
}

function ProfileScreen() {
  const monthly = [2, 4, 6, 5, 4, 3];
  return (
    <section className="screen profile-screen">
      <ScreenHeader eyebrow="Your tennis profile" title="Performance" action={<Avatar initials="ER" tone="lime" size="lg" />} />
      <div className="performance-stats">
        <div><strong>24</strong><span>Matches</span></div><div><strong>15</strong><span>Wins</span></div><div><strong>9</strong><span>Losses</span></div><div className="accent"><strong>63%</strong><span>Win rate</span></div>
      </div>
      <div className="performance-grid">
        <section className="streak-card"><div><small>Current streak</small><strong>3 Wins</strong><span>Best this season</span></div><Award /></section>
        <section className="form-card"><small>Recent form</small><div>{["W", "W", "W", "L", "W"].map((result, index) => <span key={index} className={result === "W" ? "win" : ""}>{result}</span>)}</div></section>
      </div>
      <div className="analytics-grid">
        <section className="chart-card"><div className="section-heading"><h2>Matches played</h2><span>Last 6 months</span></div><div className="bar-chart">{monthly.map((value, index) => <div key={index}><i style={{ height: `${value * 13}%` }} /><strong>{value}</strong><span>{["Jan", "Feb", "Mar", "Apr", "May", "Jun"][index]}</span></div>)}</div></section>
        <section className="chart-card"><div className="section-heading"><h2>Win rate</h2><strong className="chart-total">63%</strong></div><div className="win-rate-visual"><div className="win-ring"><span>63%</span></div><p>Up 8% from your first six matches.</p></div></section>
        <section className="activity-card"><div className="section-heading"><h2>Monthly activity</h2><span>Matches per week</span></div><div className="activity-dots">{Array.from({ length: 42 }, (_, index) => <i key={index} className={index % 4 === 0 || index % 7 === 2 ? "active" : index % 5 === 0 ? "mid" : ""} />)}</div></section>
      </div>
      <section className="breakdown-card"><h2>Match breakdown</h2><div><span><CircleUserRound /><b>Singles</b><small>Individual matches</small></span><strong>12–6</strong></div><div><span><UsersRound /><b>Doubles</b><small>With a partner</small></span><strong>3–3</strong></div></section>
    </section>
  );
}
