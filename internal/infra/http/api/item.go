package api

import (
	"encoding/json"
	"github.com/julienschmidt/httprouter"
	log "github.com/sirupsen/logrus"
	"net/http"
)

func (h *Router) getStarredItems(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	command, err := toGetStarredItemsCommand(w, r, p)
	if err != nil {
		_ = InternalError(w, "cannot get unread items")
		return
	}

	items, err := h.itemService.GetStarredItems(command)
	if err != nil {
		_ = InternalError(w, "cannot get unread items")
		return
	}

	resp, err := toGetItemsResponse(items)
	if err != nil {
		_ = InternalError(w, "cannot get unread items")
		return
	}

	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.WithError(err).Errorf("getStarredItems: encoder %s", err)
		_ = InternalError(w, "cannot encode response")
		return
	}
}

func (h *Router) getUnreadItems(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	command, err := toGetUnreadItemsCommand(w, r, p)
	if err != nil {
		_ = InternalError(w, "cannot get unread items")
		return
	}

	items, err := h.itemService.GetUnreadItems(command)
	if err != nil {
		_ = InternalError(w, "cannot get unread items")
		return
	}

	resp, err := toGetItemsResponse(items)
	if err != nil {
		_ = InternalError(w, "cannot get unread items")
		return
	}

	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.WithError(err).Errorf("getUnreadItems: encoder %s", err)
		_ = InternalError(w, "cannot encode response")
		return
	}
}
func (h *Router) updateItem(w http.ResponseWriter, r *http.Request, p httprouter.Params) {
	command, err := toUpdateItemCommand(w, r, p)
	if err != nil {
		_ = InternalError(w, "cannot update item")
		return
	}

	if err := h.itemService.UpdateItem(command); err != nil {
		_ = InternalError(w, "cannot update item")
		return
	}

	w.WriteHeader(http.StatusNoContent)
	return
}
