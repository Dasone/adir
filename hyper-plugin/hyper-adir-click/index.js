const ALIAS_REGEX = /\b([a-zA-Z0-9_-]+dir)\b/g;

exports.decorateTerm = (Term, { React }) => {
  return class extends React.Component {
    constructor(props, context) {
      super(props, context);
      this._containerRef = null;
      this._setContainerRef = this._setContainerRef.bind(this);
      this._handleClick = this._handleClick.bind(this);
    }

    _setContainerRef(el) {
      this._containerRef = el;
    }

    _hasActiveSelection() {
      if (!window.getSelection) return false;
      const sel = String(window.getSelection()).trim();
      return sel.length > 0;
    }

    _findAliasAtPoint(clientX, clientY) {
      const root = this._containerRef;
      if (!root) return null;

      const rowsEl = root.querySelector(".xterm-rows");
      const rowNodes = rowsEl ? Array.from(rowsEl.children) : [];
      if (rowNodes.length === 0) return null;

      const screenEl = root.querySelector(".xterm-screen") || rowsEl;
      const rect = screenEl.getBoundingClientRect();
      if (!rect || rect.width <= 0 || rect.height <= 0) return null;

      const relY = clientY - rect.top;
      const relX = clientX - rect.left;
      if (relY < 0 || relY > rect.height || relX < 0 || relX > rect.width) return null;

      const rowIndex = Math.min(
        rowNodes.length - 1,
        Math.max(0, Math.floor((relY / rect.height) * rowNodes.length))
      );

      const lineText = rowNodes[rowIndex] ? rowNodes[rowIndex].textContent || "" : "";
      if (!lineText) return null;

      const approxCol = Math.max(
        0,
        Math.min(lineText.length - 1, Math.floor((relX / rect.width) * lineText.length))
      );

      ALIAS_REGEX.lastIndex = 0;
      let match;
      while ((match = ALIAS_REGEX.exec(lineText)) !== null) {
        const alias = match[1];
        const start = match.index;
        const end = start + alias.length;
        // Allow a 1-character padding around the alias token for easier clicking
        if (approxCol >= start - 1 && approxCol <= end) {
          return alias;
        }
      }

      return null;
    }

    _handleClick(event) {
      if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
        return;
      }
      if (this._hasActiveSelection()) {
        return;
      }

      const aliasName = this._findAliasAtPoint(event.clientX, event.clientY);
      if (!aliasName) return;

      const uid = this.props.uid;
      if (uid && window.rpc) {
        window.rpc.emit("data", { uid, data: `${aliasName}\r` });
      }
    }

    render() {
      return React.createElement(
        "div",
        {
          ref: this._setContainerRef,
          style: { width: "100%", height: "100%" },
          onClick: this._handleClick,
        },
        React.createElement(Term, this.props)
      );
    }
  };
};
