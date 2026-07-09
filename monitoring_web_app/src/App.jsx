import { useEffect, useMemo, useState } from 'react';
import {
  apiRequest,
  clearSession,
  getStoredApiBaseUrl,
  getStoredSession,
  loginRequest,
  saveSession,
  setStoredApiBaseUrl,
  unwrapData,
} from './lib/api';

const INITIAL_LOGIN = {
  username: 'admin',
  password: '',
};

const INITIAL_READING = {
  id_parameter: '',
  nilai: '',
};

const INITIAL_SERVICE = {
  service_type: 'inspection',
  description: '',
  next_service_date: '',
  id_komponen: '',
};

const NAV_ITEMS = [
  { id: 'overview', label: 'Overview' },
  { id: 'operations', label: 'Operations' },
  { id: 'alerts', label: 'Alerts' },
  { id: 'history', label: 'History' },
];

function formatNumber(value) {
  if (value === null || value === undefined || value === '') {
    return '-';
  }

  const numeric = Number(value);
  if (Number.isNaN(numeric)) {
    return String(value);
  }

  return new Intl.NumberFormat('en-US', {
    maximumFractionDigits: 2,
  }).format(numeric);
}

function formatDateTime(value) {
  if (!value) {
    return '-';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return String(value);
  }

  return new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
}

function safeLower(value) {
  return String(value || '').toLowerCase();
}

function countOpenAlerts(alerts) {
  return alerts.filter((item) => safeLower(item.status) === 'open' || !item.is_resolved).length;
}

function App() {
  const [apiBaseUrl, setApiBaseUrl] = useState(getStoredApiBaseUrl());
  const [session, setSession] = useState(getStoredSession());
  const [loginForm, setLoginForm] = useState(INITIAL_LOGIN);
  const [readingForm, setReadingForm] = useState(INITIAL_READING);
  const [serviceForm, setServiceForm] = useState(INITIAL_SERVICE);
  const [stations, setStations] = useState([]);
  const [machines, setMachines] = useState([]);
  const [komponen, setKomponen] = useState([]);
  const [parameters, setParameters] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [serviceHistory, setServiceHistory] = useState([]);
  const [latestReadings, setLatestReadings] = useState([]);
  const [historySeries, setHistorySeries] = useState([]);
  const [selectedStationId, setSelectedStationId] = useState('');
  const [selectedMachineId, setSelectedMachineId] = useState('');
  const [selectedKomponenId, setSelectedKomponenId] = useState('');
  const [selectedParameterId, setSelectedParameterId] = useState('');
  const [loadingAuth, setLoadingAuth] = useState(Boolean(session.token));
  const [loadingData, setLoadingData] = useState(false);
  const [loadingComponentData, setLoadingComponentData] = useState(false);
  const [loginError, setLoginError] = useState('');
  const [message, setMessage] = useState({ type: '', text: '' });

  const activeStation = useMemo(
    () => stations.find((item) => String(item.id_station) === String(selectedStationId)),
    [stations, selectedStationId],
  );

  const filteredMachines = useMemo(() => {
    if (!selectedStationId) {
      return machines;
    }

    return machines.filter((item) => String(item.id_station) === String(selectedStationId));
  }, [machines, selectedStationId]);

  const filteredKomponen = useMemo(() => {
    if (!selectedMachineId) {
      return komponen;
    }

    return komponen.filter((item) => String(item.id_mesin) === String(selectedMachineId));
  }, [komponen, selectedMachineId]);

  const selectedKomponen = useMemo(
    () => komponen.find((item) => String(item.id_komponen) === String(selectedKomponenId)),
    [komponen, selectedKomponenId],
  );

  const selectedParameter = useMemo(
    () => parameters.find((item) => String(item.id_parameter) === String(selectedParameterId)),
    [parameters, selectedParameterId],
  );

  const summary = useMemo(() => {
    const machineHealth = machines.length
      ? machines.reduce((total, item) => total + Number(item.health_mesin || 0), 0) / machines.length
      : 0;

    const stationHealth = stations.length
      ? stations.reduce((total, item) => total + Number(item.health_station || 0), 0) / stations.length
      : 0;

    return {
      stationCount: stations.length,
      machineCount: machines.length,
      componentCount: komponen.length,
      parameterCount: parameters.length,
      openAlertCount: countOpenAlerts(alerts),
      averageStationHealth: stationHealth,
      averageMachineHealth: machineHealth,
    };
  }, [stations, machines, komponen, parameters, alerts]);

  async function loadDashboard(nextToken = session.token, nextApiBaseUrl = apiBaseUrl) {
    if (!nextToken) {
      return;
    }

    setLoadingData(true);
    setMessage({ type: '', text: '' });

    try {
      const [stationPayload, machinePayload, komponenPayload, parameterPayload, alertPayload, servicePayload] =
        await Promise.all([
          apiRequest('/stations?limit=200', { apiBaseUrl: nextApiBaseUrl, token: nextToken }),
          apiRequest('/machines?limit=200', { apiBaseUrl: nextApiBaseUrl, token: nextToken }),
          apiRequest('/komponen?limit=200', { apiBaseUrl: nextApiBaseUrl, token: nextToken }),
          apiRequest('/parameters?limit=200', { apiBaseUrl: nextApiBaseUrl, token: nextToken }),
          apiRequest('/service-alerts?limit=25', { apiBaseUrl: nextApiBaseUrl, token: nextToken }),
          apiRequest('/service-history?limit=25', { apiBaseUrl: nextApiBaseUrl, token: nextToken }),
        ]);

      setStations(unwrapData(stationPayload));
      setMachines(unwrapData(machinePayload));
      setKomponen(unwrapData(komponenPayload));
      setParameters(unwrapData(parameterPayload));
      setAlerts(unwrapData(alertPayload));
      setServiceHistory(unwrapData(servicePayload));
    } catch (error) {
      setMessage({ type: 'error', text: error.message });
    } finally {
      setLoadingData(false);
    }
  }

  async function loadSelectedComponentData(componentId, parameterId, nextToken = session.token, nextApiBaseUrl = apiBaseUrl) {
    if (!componentId) {
      setLatestReadings([]);
      setHistorySeries([]);
      return;
    }

    setLoadingComponentData(true);

    try {
      const [latestPayload, historyPayload] = await Promise.all([
        apiRequest(`/sensor-readings/latest/${componentId}`, {
          apiBaseUrl: nextApiBaseUrl,
          token: nextToken,
        }),
        parameterId
          ? apiRequest(
              `/sensor-readings/history?id_komponen=${componentId}&id_parameter=${parameterId}&limit=120`,
              {
                apiBaseUrl: nextApiBaseUrl,
                token: nextToken,
              },
            )
          : Promise.resolve({ data: [] }),
      ]);

      setLatestReadings(unwrapData(latestPayload));
      setHistorySeries(unwrapData(historyPayload));
    } catch (error) {
      setMessage({ type: 'error', text: error.message });
      setLatestReadings([]);
      setHistorySeries([]);
    } finally {
      setLoadingComponentData(false);
    }
  }

  useEffect(() => {
    if (!session.token) {
      setLoadingAuth(false);
      return;
    }

    let alive = true;

    async function bootstrap() {
      try {
        const mePayload = await apiRequest('/auth/me', {
          apiBaseUrl,
          token: session.token,
        });

        if (!alive) {
          return;
        }

        const user = unwrapData(mePayload);
        setSession((current) => ({ ...current, user }));
        saveSession(session.token, user);
        await loadDashboard(session.token, apiBaseUrl);
      } catch (error) {
        if (!alive) {
          return;
        }

        clearSession();
        setSession({ token: '', user: null });
        setMessage({ type: 'error', text: 'Session expired. Please login again.' });
      } finally {
        if (alive) {
          setLoadingAuth(false);
        }
      }
    }

    bootstrap();

    return () => {
      alive = false;
    };
  }, []);

  useEffect(() => {
    if (!stations.length) {
      return;
    }

    if (!selectedStationId || !stations.some((item) => String(item.id_station) === String(selectedStationId))) {
      setSelectedStationId(String(stations[0].id_station));
    }
  }, [stations, selectedStationId]);

  useEffect(() => {
    if (!machines.length) {
      return;
    }

    const candidateMachines = selectedStationId
      ? machines.filter((item) => String(item.id_station) === String(selectedStationId))
      : machines;

    if (!candidateMachines.length) {
      return;
    }

    if (!selectedMachineId || !candidateMachines.some((item) => String(item.id_mesin) === String(selectedMachineId))) {
      setSelectedMachineId(String(candidateMachines[0].id_mesin));
    }
  }, [machines, selectedStationId, selectedMachineId]);

  useEffect(() => {
    const candidateKomponen = selectedMachineId
      ? komponen.filter((item) => String(item.id_mesin) === String(selectedMachineId))
      : komponen;

    if (!candidateKomponen.length) {
      return;
    }

    if (
      !selectedKomponenId ||
      !candidateKomponen.some((item) => String(item.id_komponen) === String(selectedKomponenId))
    ) {
      setSelectedKomponenId(String(candidateKomponen[0].id_komponen));
      setReadingForm((current) => ({ ...current, id_parameter: '' }));
      setServiceForm((current) => ({ ...current, id_komponen: String(candidateKomponen[0].id_komponen) }));
    }
  }, [komponen, selectedMachineId, selectedKomponenId]);

  useEffect(() => {
    if (!parameters.length) {
      return;
    }

    if (!selectedParameterId || !parameters.some((item) => String(item.id_parameter) === String(selectedParameterId))) {
      setSelectedParameterId(String(parameters[0].id_parameter));
      setReadingForm((current) => ({ ...current, id_parameter: String(parameters[0].id_parameter) }));
    }
  }, [parameters, selectedParameterId]);

  useEffect(() => {
    if (!session.token || !selectedKomponenId) {
      return;
    }

    const activeParameterId = selectedParameterId || readingForm.id_parameter;
    loadSelectedComponentData(selectedKomponenId, activeParameterId, session.token, apiBaseUrl);
  }, [session.token, apiBaseUrl, selectedKomponenId, selectedParameterId]);

  useEffect(() => {
    if (selectedKomponenId) {
      setReadingForm((current) => ({
        ...current,
        id_parameter: current.id_parameter || selectedParameterId || '',
      }));
      setServiceForm((current) => ({
        ...current,
        id_komponen: current.id_komponen || selectedKomponenId,
      }));
    }
  }, [selectedKomponenId, selectedParameterId]);

  async function handleLogin(event) {
    event.preventDefault();
    setLoadingAuth(true);
    setLoginError('');

    try {
      const response = await loginRequest(apiBaseUrl, loginForm.username, loginForm.password);
      const payload = response?.data || response;
      const user = payload.user || payload;
      const token = payload.token;

      if (!token) {
        throw new Error('Login response does not include a token');
      }

      saveSession(token, user);
      setSession({ token, user });
      setMessage({ type: 'success', text: 'Login successful.' });
      await loadDashboard(token, apiBaseUrl);
    } catch (error) {
      setLoginError(error.message);
    } finally {
      setLoadingAuth(false);
    }
  }

  async function handleSaveApiBaseUrl(event) {
    event.preventDefault();
    setStoredApiBaseUrl(apiBaseUrl);
    setMessage({ type: 'success', text: `API base URL saved: ${apiBaseUrl}` });

    if (session.token) {
      await loadDashboard(session.token, apiBaseUrl);
    }
  }

  async function handleLogout() {
    clearSession();
    setSession({ token: '', user: null });
    setStations([]);
    setMachines([]);
    setKomponen([]);
    setParameters([]);
    setAlerts([]);
    setServiceHistory([]);
    setLatestReadings([]);
    setHistorySeries([]);
    setMessage({ type: 'success', text: 'Logged out.' });
  }

  async function handleSubmitReading(event) {
    event.preventDefault();

    if (!selectedKomponenId || !readingForm.id_parameter) {
      setMessage({ type: 'error', text: 'Select component and parameter first.' });
      return;
    }

    try {
      await apiRequest('/sensor-readings', {
        apiBaseUrl,
        token: session.token,
        method: 'POST',
        body: {
          id_komponen: Number(selectedKomponenId),
          id_parameter: Number(readingForm.id_parameter),
          nilai: Number(readingForm.nilai),
        },
      });

      setReadingForm((current) => ({ ...current, nilai: '' }));
      setMessage({ type: 'success', text: 'Sensor reading submitted.' });
      await loadDashboard(session.token, apiBaseUrl);
      await loadSelectedComponentData(selectedKomponenId, readingForm.id_parameter, session.token, apiBaseUrl);
    } catch (error) {
      setMessage({ type: 'error', text: error.message });
    }
  }

  async function handleSubmitService(event) {
    event.preventDefault();

    if (!serviceForm.id_komponen || !selectedMachineId || !selectedStationId || !session.user?.id_user) {
      setMessage({ type: 'error', text: 'Select station, machine, component, and login user first.' });
      return;
    }

    try {
      await apiRequest('/service-history', {
        apiBaseUrl,
        token: session.token,
        method: 'POST',
        body: {
          id_user: Number(session.user.id_user),
          id_station: Number(selectedStationId),
          id_mesin: Number(selectedMachineId),
          id_komponen: Number(serviceForm.id_komponen),
          service_type: serviceForm.service_type,
          description: serviceForm.description,
          next_service_date: serviceForm.next_service_date || null,
        },
      });

      setServiceForm((current) => ({
        ...current,
        description: '',
        next_service_date: '',
      }));
      setMessage({ type: 'success', text: 'Service history saved.' });
      await loadDashboard(session.token, apiBaseUrl);
    } catch (error) {
      setMessage({ type: 'error', text: error.message });
    }
  }

  async function handleAcknowledgeAlert(alertId) {
    try {
      await apiRequest(`/service-alerts/${alertId}/acknowledge`, {
        apiBaseUrl,
        token: session.token,
        method: 'PATCH',
      });

      setMessage({ type: 'success', text: 'Alert acknowledged.' });
      await loadDashboard(session.token, apiBaseUrl);
    } catch (error) {
      setMessage({ type: 'error', text: error.message });
    }
  }

  async function handleResolveAlert(alertId) {
    try {
      await apiRequest(`/service-alerts/${alertId}/resolve`, {
        apiBaseUrl,
        token: session.token,
        method: 'PATCH',
      });

      setMessage({ type: 'success', text: 'Alert resolved.' });
      await loadDashboard(session.token, apiBaseUrl);
    } catch (error) {
      setMessage({ type: 'error', text: error.message });
    }
  }

  if (loadingAuth) {
    return (
      <main className="shell shell--centered">
        <div className="loading-card">
          <div className="spinner" />
          <p>Loading monitoring console...</p>
        </div>
      </main>
    );
  }

  if (!session.token) {
    return (
      <main className="shell auth-shell">
        <section className="auth-hero panel panel--hero">
          <span className="eyebrow">Factory monitoring web</span>
          <h1>Operational visibility for stations, machines, and components.</h1>
          <p>
            Connect this web frontend to the existing backend, sign in, and monitor health,
            alerts, and maintenance history from one place.
          </p>

          <div className="hero-metrics">
            <div>
              <strong>{summary.stationCount}</strong>
              <span>Stations</span>
            </div>
            <div>
              <strong>{summary.machineCount}</strong>
              <span>Machines</span>
            </div>
            <div>
              <strong>{summary.openAlertCount}</strong>
              <span>Open alerts</span>
            </div>
          </div>
        </section>

        <section className="panel auth-form-panel">
          <form onSubmit={handleSaveApiBaseUrl} className="inline-form">
            <label>
              API base URL
              <input
                value={apiBaseUrl}
                onChange={(event) => setApiBaseUrl(event.target.value)}
                placeholder="http://localhost:3000/api"
              />
            </label>
            <button type="submit" className="button button--secondary">
              Save URL
            </button>
          </form>

          <form onSubmit={handleLogin} className="auth-form">
            <label>
              Username
              <input
                value={loginForm.username}
                onChange={(event) => setLoginForm((current) => ({ ...current, username: event.target.value }))}
                autoComplete="username"
              />
            </label>
            <label>
              Password
              <input
                type="password"
                value={loginForm.password}
                onChange={(event) => setLoginForm((current) => ({ ...current, password: event.target.value }))}
                autoComplete="current-password"
              />
            </label>
            {loginError ? <p className="form-error">{loginError}</p> : null}
            <button type="submit" className="button button--primary" disabled={loadingAuth}>
              {loadingAuth ? 'Signing in...' : 'Sign in'}
            </button>
          </form>
        </section>
      </main>
    );
  }

  return (
    <main className="shell dashboard-shell">
      <aside className="sidebar panel">
        <div>
          <span className="eyebrow">Monitoring console</span>
          <h2>Factory control</h2>
          <p className="muted">Signed in as {session.user?.nama_lengkap || session.user?.username || 'user'}</p>
        </div>

        <nav className="nav-list">
          {NAV_ITEMS.map((item) => (
            <a key={item.id} href={`#${item.id}`}>
              {item.label}
            </a>
          ))}
        </nav>

        <div className="sidebar-card">
          <span>API</span>
          <strong>{apiBaseUrl}</strong>
        </div>

        <button type="button" className="button button--ghost" onClick={handleLogout}>
          Logout
        </button>
      </aside>

      <section className="content">
        <header className="panel hero-panel" id="overview">
          <div className="hero-copy">
            <span className="eyebrow">Live machine health</span>
            <h1>Command center for maintenance and sensor readings.</h1>
            <p>
              Review stations, machines, tracked components, alert status, and service history from the
              existing backend endpoints.
            </p>
            <p className="muted">
              Active station: {activeStation?.nama_station || 'select a station'}
            </p>
          </div>

          <form className="inline-form inline-form--compact" onSubmit={handleSaveApiBaseUrl}>
            <label>
              API base URL
              <input
                value={apiBaseUrl}
                onChange={(event) => setApiBaseUrl(event.target.value)}
              />
            </label>
            <button type="submit" className="button button--secondary">
              Save
            </button>
            <button
              type="button"
              className="button button--primary"
              onClick={() => loadDashboard(session.token, apiBaseUrl)}
              disabled={loadingData}
            >
              {loadingData ? 'Refreshing...' : 'Refresh'}
            </button>
          </form>
        </header>

        {message.text ? <div className={`banner banner--${message.type || 'info'}`}>{message.text}</div> : null}

        <section className="stats-grid">
          <article className="panel stat-card">
            <span>Stations</span>
            <strong>{summary.stationCount}</strong>
            <small>Average health {formatNumber(summary.averageStationHealth)}%</small>
          </article>
          <article className="panel stat-card">
            <span>Machines</span>
            <strong>{summary.machineCount}</strong>
            <small>Average health {formatNumber(summary.averageMachineHealth)}%</small>
          </article>
          <article className="panel stat-card">
            <span>Components</span>
            <strong>{summary.componentCount}</strong>
            <small>Tracked objects on the floor</small>
          </article>
          <article className="panel stat-card">
            <span>Open alerts</span>
            <strong>{summary.openAlertCount}</strong>
            <small>Needs attention right now</small>
          </article>
        </section>

        <section className="panel section-panel" id="operations">
          <div className="section-heading">
            <div>
              <span className="eyebrow">Operations</span>
              <h3>Pick a station, machine, and component</h3>
            </div>
            <button type="button" className="button button--ghost" onClick={() => loadDashboard(session.token, apiBaseUrl)}>
              {loadingData ? 'Syncing...' : 'Sync data'}
            </button>
          </div>

          <div className="selection-grid">
            <label>
              Station
              <select value={selectedStationId} onChange={(event) => setSelectedStationId(event.target.value)}>
                {stations.map((item) => (
                  <option key={item.id_station} value={item.id_station}>
                    {item.nama_station}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Machine
              <select value={selectedMachineId} onChange={(event) => setSelectedMachineId(event.target.value)}>
                {filteredMachines.map((item) => (
                  <option key={item.id_mesin} value={item.id_mesin}>
                    {item.nama_mesin}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Component
              <select value={selectedKomponenId} onChange={(event) => setSelectedKomponenId(event.target.value)}>
                {filteredKomponen.map((item) => (
                  <option key={item.id_komponen} value={item.id_komponen}>
                    {item.nama_komponen}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Parameter
              <select
                value={selectedParameterId}
                onChange={(event) => {
                  setSelectedParameterId(event.target.value);
                  setReadingForm((current) => ({ ...current, id_parameter: event.target.value }));
                }}
              >
                {parameters.map((item) => (
                  <option key={item.id_parameter} value={item.id_parameter}>
                    {item.nama_parameter}
                    {item.satuan ? ` (${item.satuan})` : ''}
                  </option>
                ))}
              </select>
            </label>
          </div>

          <div className="detail-grid">
            <article className="panel nested-panel">
              <div className="section-heading section-heading--small">
                <div>
                  <span className="eyebrow">Latest readings</span>
                  <h4>
                    {selectedKomponen?.nama_komponen || 'Select a component'}
                    {selectedParameter ? ` · ${selectedParameter.nama_parameter}` : ''}
                  </h4>
                </div>
                {loadingComponentData ? <span className="pill">Loading</span> : null}
              </div>

              <div className="reading-list">
                {latestReadings.length ? (
                  latestReadings.map((item) => (
                    <div className="reading-item" key={`${item.id_parameter}-${item.recorded_at}`}>
                      <div>
                        <strong>{item.nama_parameter}</strong>
                        <span>{formatDateTime(item.recorded_at)}</span>
                      </div>
                      <div>
                        <strong>{formatNumber(item.nilai)}</strong>
                        <span>{item.satuan || '-'}</span>
                      </div>
                    </div>
                  ))
                ) : (
                  <p className="empty-state">No latest reading available for the selected component.</p>
                )}
              </div>

              <form className="stack-form" onSubmit={handleSubmitReading}>
                <h4>Submit new sensor reading</h4>
                <label>
                  Parameter
                  <select
                    value={readingForm.id_parameter}
                    onChange={(event) => setReadingForm((current) => ({ ...current, id_parameter: event.target.value }))}
                  >
                    {parameters.map((item) => (
                      <option key={item.id_parameter} value={item.id_parameter}>
                        {item.nama_parameter}
                      </option>
                    ))}
                  </select>
                </label>
                <label>
                  Value
                  <input
                    type="number"
                    step="any"
                    value={readingForm.nilai}
                    onChange={(event) => setReadingForm((current) => ({ ...current, nilai: event.target.value }))}
                    placeholder="42.5"
                  />
                </label>
                <button type="submit" className="button button--primary">Send reading</button>
              </form>
            </article>

            <article className="panel nested-panel">
              <div className="section-heading section-heading--small">
                <div>
                  <span className="eyebrow">Maintenance</span>
                  <h4>Log service activity</h4>
                </div>
              </div>

              <form className="stack-form" onSubmit={handleSubmitService}>
                <label>
                  Service type
                  <select
                    value={serviceForm.service_type}
                    onChange={(event) => setServiceForm((current) => ({ ...current, service_type: event.target.value }))}
                  >
                    <option value="preventive">preventive</option>
                    <option value="corrective">corrective</option>
                    <option value="calibration">calibration</option>
                    <option value="inspection">inspection</option>
                  </select>
                </label>
                <label>
                  Component
                  <select
                    value={serviceForm.id_komponen}
                    onChange={(event) => setServiceForm((current) => ({ ...current, id_komponen: event.target.value }))}
                  >
                    {filteredKomponen.map((item) => (
                      <option key={item.id_komponen} value={item.id_komponen}>
                        {item.nama_komponen}
                      </option>
                    ))}
                  </select>
                </label>
                <label>
                  Next service date
                  <input
                    type="datetime-local"
                    value={serviceForm.next_service_date}
                    onChange={(event) => setServiceForm((current) => ({ ...current, next_service_date: event.target.value }))}
                  />
                </label>
                <label>
                  Description
                  <textarea
                    rows="5"
                    value={serviceForm.description}
                    onChange={(event) => setServiceForm((current) => ({ ...current, description: event.target.value }))}
                    placeholder="Write what was checked or repaired"
                  />
                </label>
                <button type="submit" className="button button--primary">Save service log</button>
              </form>
            </article>
          </div>
        </section>

        <section className="panel section-panel" id="alerts">
          <div className="section-heading">
            <div>
              <span className="eyebrow">Alerts</span>
              <h3>Open incidents and recent service alerts</h3>
            </div>
          </div>

          <div className="list-grid">
            {alerts.length ? (
              alerts.map((item) => (
                <article className="list-card" key={item.id_alert}>
                  <div className="list-card__top">
                    <div>
                      <strong>{item.description || 'Alert'}</strong>
                      <p>
                        {item.status || 'open'} · {item.severity || 'medium'}
                      </p>
                    </div>
                    <span className={`pill pill--${safeLower(item.severity)}`}>{item.severity || 'medium'}</span>
                  </div>

                  <div className="meta-row">
                    <span>Machine #{item.id_mesin}</span>
                    <span>Component #{item.id_komponen}</span>
                  </div>

                  <div className="action-row">
                    <button type="button" className="button button--ghost" onClick={() => handleAcknowledgeAlert(item.id_alert)}>
                      Acknowledge
                    </button>
                    <button type="button" className="button button--secondary" onClick={() => handleResolveAlert(item.id_alert)}>
                      Resolve
                    </button>
                  </div>
                </article>
              ))
            ) : (
              <p className="empty-state">No alert record found.</p>
            )}
          </div>
        </section>

        <section className="panel section-panel" id="history">
          <div className="section-heading">
            <div>
              <span className="eyebrow">History</span>
              <h3>Maintenance logs and recent readings</h3>
            </div>
          </div>

          <div className="history-grid">
            <article className="nested-panel panel">
              <h4>Service history</h4>
              <div className="timeline-list">
                {serviceHistory.length ? (
                  serviceHistory.map((item) => (
                    <div className="timeline-item" key={item.id_service}>
                      <strong>{item.service_type || 'service'}</strong>
                      <span>{formatDateTime(item.service_date || item.created_at)}</span>
                      <p>{item.description || 'No description'}</p>
                    </div>
                  ))
                ) : (
                  <p className="empty-state">No service history yet.</p>
                )}
              </div>
            </article>

            <article className="nested-panel panel">
              <h4>Reading history</h4>
              <div className="timeline-list">
                {historySeries.length ? (
                  historySeries.map((item) => (
                    <div className="timeline-item" key={item.id_reading}>
                      <strong>{formatNumber(item.nilai)}</strong>
                      <span>{formatDateTime(item.recorded_at)}</span>
                    </div>
                  ))
                ) : (
                  <p className="empty-state">No reading history for the selected component and parameter.</p>
                )}
              </div>
            </article>
          </div>
        </section>

        <section className="panel section-panel">
          <div className="section-heading">
            <div>
              <span className="eyebrow">Inventory</span>
              <h3>Stations, machines, and components</h3>
            </div>
          </div>

          <div className="table-grid">
            <article className="table-panel">
              <h4>Stations</h4>
              <div className="table-list">
                {stations.map((item) => (
                  <div className="table-row" key={item.id_station}>
                    <div>
                      <strong>{item.nama_station}</strong>
                      <span>{item.lokasi_station}</span>
                    </div>
                    <span>{formatNumber(item.health_station)}%</span>
                  </div>
                ))}
              </div>
            </article>

            <article className="table-panel">
              <h4>Machines</h4>
              <div className="table-list">
                {machines.map((item) => (
                  <div className="table-row" key={item.id_mesin}>
                    <div>
                      <strong>{item.nama_mesin}</strong>
                      <span>Station #{item.id_station}</span>
                    </div>
                    <span>{formatNumber(item.health_mesin)}%</span>
                  </div>
                ))}
              </div>
            </article>

            <article className="table-panel">
              <h4>Components</h4>
              <div className="table-list">
                {komponen.map((item) => (
                  <div className="table-row" key={item.id_komponen}>
                    <div>
                      <strong>{item.nama_komponen}</strong>
                      <span>Machine #{item.id_mesin}</span>
                    </div>
                    <span>{formatNumber(item.avg_health_all_parameter)}%</span>
                  </div>
                ))}
              </div>
            </article>
          </div>
        </section>
      </section>
    </main>
  );
}

export default App;