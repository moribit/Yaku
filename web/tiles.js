// Tile -> renderer -> SVG/CSS. Replace this module to change artwork.
const names = { man: "萬", pin: "筒", sou: "索", honor: "" };
const honors = ["東", "南", "西", "北", "白", "發", "中"];
const numerals = ["一", "二", "三", "四", "五", "六", "七", "八", "九"];
const namespace = "http://www.w3.org/2000/svg";
function svgNode(tag, attrs) {
  const node = document.createElementNS(namespace, tag);
  for (const [name, value] of Object.entries(attrs))
    node.setAttribute(name, value);
  return node;
}
function pips(value, bamboo) {
  const svg = svgNode("svg", { viewBox: "0 0 36 46", "aria-hidden": "true" });
  const positions = {
    1: [[18, 23]],
    2: [
      [18, 12],
      [18, 34],
    ],
    3: [
      [10, 9],
      [18, 23],
      [26, 37],
    ],
    4: [
      [9, 11],
      [27, 11],
      [9, 35],
      [27, 35],
    ],
    5: [
      [9, 9],
      [27, 9],
      [18, 23],
      [9, 37],
      [27, 37],
    ],
    6: [
      [9, 9],
      [27, 9],
      [9, 23],
      [27, 23],
      [9, 37],
      [27, 37],
    ],
    7: [
      [18, 7],
      [9, 19],
      [27, 19],
      [9, 30],
      [27, 30],
      [9, 41],
      [27, 41],
    ],
    8: [
      [9, 7],
      [27, 7],
      [9, 18],
      [27, 18],
      [9, 29],
      [27, 29],
      [9, 40],
      [27, 40],
    ],
    9: [
      [7, 9],
      [18, 9],
      [29, 9],
      [7, 23],
      [18, 23],
      [29, 23],
      [7, 37],
      [18, 37],
      [29, 37],
    ],
  };
  for (const [x, y] of positions[value]) {
    if (bamboo) {
      svg.append(
        svgNode("rect", {
          x: x - 2.4,
          y: y - 4.5,
          width: 4.8,
          height: 9,
          rx: 1.6,
          fill: "#39766b",
        }),
      );
      svg.append(
        svgNode("path", {
          d: `M${x - 2.5} ${y}h5`,
          stroke: "#e7f0dc",
          "stroke-width": 1.2,
        }),
      );
    } else {
      svg.append(
        svgNode("circle", {
          cx: x,
          cy: y,
          r: value === 1 ? 10 : 4.5,
          fill: x === 18 && y === 23 ? "#b74f45" : "#36577b",
        }),
      );
      svg.append(
        svgNode("circle", {
          cx: x,
          cy: y,
          r: value === 1 ? 6 : 2.1,
          fill: "none",
          stroke: "#fbfaf5",
          "stroke-width": 1.2,
        }),
      );
    }
  }
  return svg;
}
export function tileLabel(tile) {
  return tile.suit === "honor"
    ? honors[tile.value - 1]
    : `${tile.value}${names[tile.suit]}`;
}
export function renderTile(tile, { winning = false } = {}) {
  const el = document.createElement("span");
  el.className = `tile ${tile.suit}${winning ? " winning" : ""}`;
  el.setAttribute("role", "img");
  el.setAttribute(
    "aria-label",
    `${tileLabel(tile)}${winning ? "（和了牌）" : ""}`,
  );
  const art = document.createElement("span");
  art.className = "tile-art";
  if (tile.suit === "pin" || tile.suit === "sou")
    art.append(pips(tile.value, tile.suit === "sou"));
  else {
    art.textContent =
      tile.suit === "man" ? numerals[tile.value - 1] : honors[tile.value - 1];
    if (tile.suit === "honor" && tile.value === 5)
      art.classList.add("white-dragon");
  }
  el.append(art);
  const label = document.createElement("span");
  label.className = "tile-caption";
  label.textContent =
    tile.suit === "man"
      ? "萬"
      : tile.suit === "honor"
        ? "字牌"
        : `${tile.value}${names[tile.suit]}`;
  el.append(label);
  if (tile.suit === "honor" && tile.value === 6) el.classList.add("green");
  if (tile.suit === "honor" && tile.value === 7) el.classList.add("red");
  return el;
}
export function renderHand(tiles, target, winningTile = null) {
  let highlighted = false;
  // Sort visually while preserving the DTO, then mark exactly one winning tile.
  const suits = ["man", "pin", "sou", "honor"];
  const sorted = [...tiles].sort(
    (a, b) =>
      suits.indexOf(a.suit) - suits.indexOf(b.suit) || a.value - b.value,
  );
  sorted.forEach((tile) => {
    const winning =
      !highlighted &&
      winningTile &&
      tile.suit === winningTile.suit &&
      tile.value === winningTile.value;
    if (winning) highlighted = true;
    target.append(renderTile(tile, { winning }));
  });
}
