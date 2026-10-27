const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function setup() {
  const scripts = [];
  let reloads = 0;
  const context = {
    Controller: class {}, Promise, setTimeout, clearTimeout,
    window: { location: { pathname: '/events/new', reload() { reloads++; } } },
    sessionStorage: { getItem() { return null; }, setItem() {}, removeItem() {} },
    navigator: {},
    document: {
      head: { appendChild(script) { scripts.push(script); } },
      createElement() {
        return { handlers: {}, addEventListener(name, handler) { this.handlers[name] = handler; }, remove() {} };
      }
    }
  };
  const source = fs.readFileSync(path.join(__dirname, '../../app/javascript/controllers/location_picker_controller.js'), 'utf8')
    .replace(/^import .*$/m, '')
    .replace('export default class', 'globalThis.Subject = class');
  vm.createContext(context);
  vm.runInContext(source, context);
  const subject = new context.Subject();
  const fields = { name: 'Training meeting', description: 'Keep this draft', starts_at: '2026-10-28T16:30', ends_at: '2026-10-28T17:30' };
  subject.element = { isConnected: true, fields };
  for (const name of ['latitude', 'longitude', 'name', 'query']) {
    subject[`${name}Target`] = { value: name === 'name' ? 'Training Hall' : '', focus() { this.focused = true; } };
  }
  subject.statusTarget = { textContent: '', dataset: {}, style: {} };
  subject.mapFrameTarget = { hidden: false };
  subject.mapErrorTarget = { textContent: '', hidden: true };
  subject.mapErrorMessageValue = 'The map could not be loaded. Your event details are still here.';
  subject.missingLocationMessageValue = 'Enter valid latitude and longitude together, or leave both blank.';
  subject.missingNameMessageValue = 'Give this location a name or address.';
  return { subject, context, scripts, fields, reloads: () => reloads };
}

test('a delayed map loads without navigating or replacing the event draft', async () => {
  const { subject, context, scripts, fields, reloads } = setup();
  let initialized = 0;
  subject.initMap = () => initialized++;
  const connected = subject.connect();
  fields.name = 'Edited while the map loads';
  assert.equal(initialized, 0);
  assert.equal(scripts.length, 1);
  context.window.L = {};
  scripts[0].handlers.load();
  await connected;
  assert.equal(initialized, 1);
  assert.equal(fields.name, 'Edited while the map loads');
  assert.equal(fields.description, 'Keep this draft');
  assert.equal(fields.starts_at, '2026-10-28T16:30');
  assert.equal(fields.ends_at, '2026-10-28T17:30');
  assert.equal(reloads(), 0);
});

test('a blocked map keeps the draft and choosing a saved location never reloads', async () => {
  const { subject, scripts, fields, reloads } = setup();
  const connected = subject.connect();
  scripts[0].handlers.error();
  await connected;
  assert.equal(subject.mapFrameTarget.hidden, true);
  assert.equal(subject.mapErrorTarget.hidden, false);
  assert.match(subject.mapErrorTarget.textContent, /event details are still here/);
  subject.setPoint(30.61, -96.34, { label: 'Training Hall' });
  assert.equal(subject.latitudeTarget.value, '30.610000');
  assert.equal(subject.longitudeTarget.value, '-96.340000');
  assert.deepEqual(fields, { name: 'Training meeting', description: 'Keep this draft', starts_at: '2026-10-28T16:30', ends_at: '2026-10-28T17:30' });
  assert.equal(reloads(), 0);
});

test('reconnecting during library loading shares one request and ignores the detached form', async () => {
  const { subject, context, scripts } = setup();
  let initialized = 0;
  subject.initMap = () => initialized++;
  const connected = subject.connect();
  subject.disconnect();
  const reconnected = subject.connect();
  context.window.L = {};
  scripts[0].handlers.load();
  await Promise.all([connected, reconnected]);
  assert.equal(initialized, 1);
  assert.equal(scripts.length, 1);
});

test('a named location can be saved without coordinates, but a partial or out-of-range pin cannot', () => {
  const { subject } = setup();
  let prevented = 0;
  const event = { preventDefault() { prevented++; } };
  subject.validate(event);
  assert.equal(prevented, 0);
  subject.latitudeTarget.value = '30.61';
  subject.validate(event);
  assert.equal(prevented, 1);
  subject.longitudeTarget.value = '-96.34';
  subject.validate(event);
  assert.equal(prevented, 1);
  subject.latitudeTarget.value = '91';
  subject.validate(event);
  assert.equal(prevented, 2);
});

test('denied geolocation leaves the draft and manual coordinates available', () => {
  const { subject, context, fields } = setup();
  subject.latitudeTarget.value = '30.61';
  subject.longitudeTarget.value = '-96.34';
  context.navigator.geolocation = { getCurrentPosition(ok, fail) { fail({ code: 1 }); } };
  subject.useMyLocation();
  assert.match(subject.statusTarget.textContent, /Enter coordinates manually/);
  assert.equal(subject.latitudeTarget.value, '30.61');
  assert.equal(subject.longitudeTarget.value, '-96.34');
  assert.equal(fields.description, 'Keep this draft');
});
