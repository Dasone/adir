const ALIAS_REGEX = /\b([a-zA-Z0-9_-]+dir)\b/g;

exports.decorateTerm = (Term, { React }) => {
  return class extends React.Component {
    constructor(props, context) {
      super(props, context);
      this._containerRef = null;
      this._setContainerRef = this._setContainerRef.bind(this);
      this._handleMouseMove = this._handleMouseMove.bind(this);
      this._handleMouseLeave = this._handleMouseLeave.bind(this);
      this._handleClick = this._handleClick.bind(this);
      this.state = { hoveringAlias: false };
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
      const screenRect = screenEl.getBoundingClientRect();
      if (!screenRect || screenRect.width <= 0 || screenRect.height <= 0) return null;

      if (
        clientX < screenRect.left ||
        clientX > screenRect.right ||
        clientY < screenRect.top ||
        clientY > screenRect.bottom
      ) {
        return null;
      }

      let rowIndex = -1;
      for (let i = 0; i < rowNodes.length; i++) {
        const r = rowNodes[i].getBoundingClientRect();
        if (clientY >= r.top && clientY <= r.bottom) {
          rowIndex = i;
          break;
        }
      }
      if (rowIndex === -1) {
        rowIndex = Math.min(
          rowNodes.length - 1,
          Math.max(0, Math.floor(((clientY - screenRect.top) / screenRect.height) * rowNodes.length))
        );
      }

      const rowEl = rowNodes[rowIndex];
      const lineText = rowEl ? rowEl.textContent || "" : "";
      if (!lineText) return null;

      const rowRect = rowEl ? rowEl.getBoundingClientRect() : screenRect;
      const effectiveWidth = rowRect.width > 0 ? rowRect.width : screenRect.width;
      const relX = Math.max(0, Math.min(effectiveWidth, clientX - rowRect.left));

      // Estimate character column from rendered line width vs character count
      const charWidth = effectiveWidth / Math.max(1, lineText.length);
      const approxCol = Math.max(
        0,
        Math.min(lineText.length - 1, Math.floor(relX / charWidth))
      );

      ALIAS_REGEX.lastIndex = 0;
      let match;
      while ((match = ALIAS_REGEX.exec(lineText)) !== null) {
        const alias = match[1];
        const start = match.index;
        const end = start + alias.length;
        if (approxCol >= start - 1 && approxCol <= end) {
          return alias;
        }
      }

      return null;
    }

    _sendAliasCommand(aliasName) {
      const payload = `${aliasName}\r`;
      const uid = this.props.uid;

      if (typeof this.props.onData === "function") {
        this.props.onData(payload);
        return true;
      }

      if (window.rpc && typeof window.rpc.emit === "function") {
        if (uid) {
          window.rpc.emit("data", { uid, data: payload });
        } else {
          window.rpc.emit("data", payload);
        }
        return true;
      }

      if (window.store && typeof window.store.dispatch === "function" && uid) {
        window.store.dispatch({
          type: "SESSION_USER_DATA",
          data: payload,
          uid,
          effect: true,
        });
        return true;
      }

      return false;
    }

    _handleMouseMove(event) {
      const aliasName = this._findAliasAtPoint(event.clientX, event.clientY);
      const isHovering = Boolean(aliasName);
      if (isHovering !== this.state.hoveringAlias) {
        this.setState({ hoveringAlias: isHovering });
      }
    }

    _handleMouseLeave() {
      if (this.state.hoveringAlias) {
        this.setState({ hoveringAlias: false });
      }
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

      this._sendAliasCommand(aliasName);
    }

    render() {
      return React.createElement(
        "div",
        {
          ref: this._setContainerRef,
          style: {
            width: "100%",
            height: "100%",
            cursor: this.state.hoveringAlias ? "pointer" : "text",
          },
          onMouseMove: this._handleMouseMove,
          onMouseLeave: this._handleMouseLeave,
          onClick: this._handleClick,
        },
        React.createElement(Term, this.props)
      );
    }
  };
};
