;;; lsp-protocol.el --- Language Sever Protocol Bindings  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Ivan Yonchovski

;; Author: Ivan Yonchovski <yyoncho@gmail.com>
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Autogenerated bindings from lsp4j using
;; https://github.com/victools/jsonschema-generator+scrips to generate
;; scripts/generated.protocol.schema.json and then
;; scripts/lsp-generate-bindings.el

;;; Code:

(require 'dash)
(require 'ht)
(require 's)

(defun lsp-keyword->symbol (keyword)
  (intern (substring (symbol-name keyword) 1)))

(defun lsp-keyword->string (keyword)
  (substring (symbol-name keyword) 1))

(defvar lsp-use-plists t)

(defmacro lsp-interface (&rest interfaces)
  "Generate LSP bindings from INTERFACES triplet.

Example usage with `dash`.

\(-let [(&ApplyWorkspaceEditResponse
  :failure-reason?) (ht (\"failureReason\" \"...\"))]
  failure-reason?)

\(fn (INTERFACE-NAME-1 REQUIRED-FIELDS-1 OPTIONAL-FIELDS-1) (INTERFACE-NAME-2 REQUIRED-FIELDS-2 OPTIONAL-FIELDS-2) ...)"
  (->> interfaces
       (-map (-lambda ((interface required optional))
               (let ((params (nconc
                              (-map (lambda (param-name)
                                      (cons
                                       (intern (concat ":" (s-dashed-words (symbol-name param-name)) "?"))
                                       param-name))
                                    optional)
                              (-map (lambda (param-name)
                                      (cons (intern (concat ":" (s-dashed-words (symbol-name param-name))))
                                            param-name))
                                    required))))
                 (cl-list*
                  `(defun ,(intern (format "dash-expand:&%s" interface)) (key source)
                     (unless (or (member key ',(-map #'cl-first params))
                                 (s-starts-with? ":_" (symbol-name key)))
                       (error "Unknown key: %s.  Available keys: %s" key ',(-map #'cl-first params)))
                     ,(if lsp-use-plists
                          ``(plist-get ,source
                                       ,(if (s-starts-with? ":_" (symbol-name key))
                                            key
                                          (cl-rest (assoc key ',params))))
                        ``(gethash ,(if (s-starts-with? ":_" (symbol-name key))
                                        (substring (symbol-name key) 1)
                                      (substring (symbol-name
                                                  (cl-rest (assoc key ',params)))
                                                 1))
                                   ,source)))
                  `(defun ,(intern (format "dash-expand:&%s?" interface)) (key source)
                     (unless (member key ',(-map #'cl-first params))
                       (error "Unknown key: %s.  Available keys: %s" key ',(-map #'cl-first params)))
                     ,(if lsp-use-plists
                          ``(plist-get ,source
                                       ,(if (s-starts-with? ":_" (symbol-name key))
                                            key
                                          (cl-rest (assoc key ',params))))
                        ``(when ,source
                            (gethash ,(substring (symbol-name
                                                  (cl-rest (assoc key ',params)))
                                                 1)
                                     ,source))))

                  `(defun ,(intern (format "lsp-%s?" (s-dashed-words (symbol-name interface)))) (object)
                     (cond
                      ((ht? object)
                       (-all? (let ((keys (ht-keys object)))
                                (lambda (prop)
                                  (member prop keys)))
                              ',(-map (lambda (field-name)
                                        (substring (symbol-name field-name) 1))
                                      required)))
                      ((listp object) (-all? (lambda (prop)
                                               (plist-member object prop))
                                             ',required))))
                  `(cl-defun ,(intern (format "lsp-make-%s" (s-dashed-words (symbol-name interface))))
                       (&key ,@(-map (-lambda ((key))
                                       (intern (substring (symbol-name key) 1))) params))

                     ,(if lsp-use-plists
                          `(let ($$result)
                             ,@(-map (-lambda ((name . key))
                                       `(when ,(lsp-keyword->symbol name)
                                          (setq $$result (plist-put $$result ,key ,(lsp-keyword->symbol name)))))
                                     params)
                             $$result)
                        `(let (($$result (ht)))
                           ,@(-map (-lambda ((name . key))
                                     `(when ,(lsp-keyword->symbol name)
                                        (puthash ,(lsp-keyword->string key) ,(lsp-keyword->symbol name) $$result)))
                                   params)
                           $$result)))
                  (-mapcat (-lambda ((label . name))
                             (list
                              `(defun ,(intern (format "lsp:%s-%s"
                                                       (s-dashed-words (symbol-name interface))
                                                       (substring (symbol-name label) 1)))
                                   (object)
                                 ,(if lsp-use-plists
                                      `(plist-get object ,name)
                                    `(when object (gethash ,(lsp-keyword->string name) object))))
                              `(defun ,(intern (format "lsp:set-%s-%s"
                                                       (s-dashed-words (symbol-name interface))
                                                       (substring (symbol-name label) 1)))
                                   (object value)
                                 ,(if lsp-use-plists
                                      `(plist-put object ,name value)
                                    `(puthash ,(lsp-keyword->string name) value object)))))
                           params)))))
       (apply #'append)
       (cl-list* 'progn)))

(if lsp-use-plists
    (progn
      (defun lsp-get (from key)
        (plist-get from key))
      (defun lsp-put (where key value)
        (plist-put where key value))
      (defun lsp-map (fn value)
        (-map (-lambda ((k v))
                (funcall fn (lsp-keyword->string k) v))
              (-partition 2 value )))
      (defalias 'lsp-merge 'append)
      (defalias 'lsp-empty? 'null))
  (defun lsp-get (from key)
    (when from
      (gethash (lsp-keyword->string key) from)))
  (defun lsp-put (where key value)
    (prog1 where
      (puthash (lsp-keyword->string key) value where)))
  (defun lsp-map (fn value)
    (when value
      (maphash fn value)))
  (defalias 'lsp-merge 'ht-merge)
  (defalias 'lsp-empty? 'ht-empty?))

(defmacro lsp-defun (name match-form &rest body)
  "Define NAME as a function which destructures its input as MATCH-FORM and executes BODY.

Note that you have to enclose the MATCH-FORM in a pair of parens,
such that:

  (-defun (x) body)
  (-defun (x y ...) body)

has the usual semantics of `defun'.  Furthermore, these get
translated into a normal `defun', so there is no performance
penalty.

See `-let' for a description of the destructuring mechanism."
  (declare (doc-string 3) (indent defun)
           (debug (&define name sexp
                           [&optional stringp]
                           [&optional ("declare" &rest sexp)]
                           [&optional ("interactive" interactive)]
                           def-body)))
  (cond
   ((nlistp match-form)
    (signal 'wrong-type-argument (list #'listp match-form)))
   ;; no destructuring, so just return regular defun to make things faster
   ((-all? #'symbolp match-form)
    `(defun ,name ,match-form ,@body))
   (t
    (-let* ((inputs (--map-indexed (list it (make-symbol (format "input%d" it-index))) match-form))
            ((body docs) (cond
                          ;; only docs
                          ((and (stringp (car body))
                                (not (cdr body)))
                           (list body (car body)))
                          ;; docs + body
                          ((stringp (car body))
                           (list (cdr body) (car body)))
                          ;; no docs
                          (t (list body))))
            ((body interactive-form) (cond
                                      ;; interactive form
                                      ((and (listp (car body))
                                            (eq (caar body) 'interactive))
                                       (list (cdr body) (car body)))
                                      ;; no interactive form
                                      (t (list body)))))
      ;; TODO: because inputs to the defun are evaluated only once,
      ;; -let* need not to create the extra bindings to ensure that.
      ;; We should find a way to optimize that.  Not critical however.
      `(defun ,name ,(-map #'cadr inputs)
         ,@(when docs (list docs))
         ,@(when interactive-form (list interactive-form))
         (-let* ,inputs ,@body))))))




;; manually defined interfaces
(defconst lsp/markup-kind-plain-text "plaintext")
(defconst lsp/markup-kind-markdown "markdown")

(lsp-interface (JSONResponse (:params :id :method :result) nil)
               (JSONResponseError (:error) nil)
               (JSONMessage nil (:params :id :method :result :error))
               (JSONResult nil (:params :id :method))
               (JSONNotification (:params :method) nil)
               (JSONRequest (:params :method) nil)
               (JSONError (:message :code) nil)
               (ProgressParams (:token :value) nil)
               (Edit (:kind) nil)
               (WorkDoneProgress (:kind) nil)
               (WorkDoneProgressBegin  (:kind :title) (:cancellable :message :percentage))
               (WorkDoneProgressReport  (:kind) (:cancellable :message :percentage))
               (WorkDoneProgressEnd  (:kind) (:message))
               (WorkDoneProgressOptions nil (:workDoneProgress))
               (SemanticTokensOptions (:legend) (:rangeProvider :documentProvider))
               (SemanticTokensLegend (:tokenTypes :tokenModifiers))
               (SematicTokensPartialResult (:data) nil))

(lsp-interface (v1:ProgressParams (:id :title) (:message :percentage :done)))

(defun dash-expand:&RangeToPoint (key source)
  "Convert the position KEY from SOURCE into a point."
  `(lsp--position-to-point
    (lsp-get ,source ,key)))

(lsp-interface (eslint:StatusParams  (:state) nil)
               (eslint:OpenESLintDocParams (:url) nil))

(lsp-interface (haxe:ProcessStartNotification (:title) nil))

(lsp-interface (pwsh:ScriptRegion (:StartLineNumber :EndLineNumber :StartColumnNumber :EndColumnNumber :Text) nil))

(lsp-interface (rls:Cmd (:args :binary :env :cwd) nil))

(defconst lsp/rust-analyzer-inlay-hint-kind-type-hint "TypeHint")
(defconst lsp/rust-analyzer-inlay-hint-kind-param-hint "ParameterHint")
(defconst lsp/rust-analyzer-inlay-hint-kind-chaining-hint "ChainingHint")
(lsp-interface (rust-analyzer:SyntaxTreeParams (:textDocument) (:range))
               (rust-analyzer:ExpandMacroParams (:textDocument :position) nil)
               (rust-analyzer:ExpandedMacro (:name :expansion) nil)
               (rust-analyzer:MatchingBraceParams (:textDocument :positions) nil)
               (rust-analyzer:ResovedCodeActionParams (:id :codeActionParams) nil)
               (rust-analyzer:JoinLinesParams (:textDocument :ranges) nil)
               (rust-analyzer:RunnablesParams (:textDocument) (:position))
               (rust-analyzer:Runnable (:label :kind :args) (:location :env :bin :extraArgs))
               (rust-analyzer:RunnableArgs (:cargoArgs :executableArgs) (:workspaceRoot))
               (rust-analyzer:InlayHint (:range :label :kind) nil)
               (rust-analyzer:InlayHintsParams (:textDocument) nil)
               (rust-analyzer:SsrParams (:query :parseOnly) nil)
               (rust-analyzer:CommandLink (:title :command) (:arguments :tooltip))
               (rust-analyzer:CommandLinkGroup (:commands) (:title)))


;; begin autogenerated code

(defconst lsp/completion-item-kind-text 1)
(defconst lsp/completion-item-kind-method 2)
(defconst lsp/completion-item-kind-function 3)
(defconst lsp/completion-item-kind-constructor 4)
(defconst lsp/completion-item-kind-field 5)
(defconst lsp/completion-item-kind-variable 6)
(defconst lsp/completion-item-kind-class 7)
(defconst lsp/completion-item-kind-interface 8)
(defconst lsp/completion-item-kind-module 9)
(defconst lsp/completion-item-kind-property 10)
(defconst lsp/completion-item-kind-unit 11)
(defconst lsp/completion-item-kind-value 12)
(defconst lsp/completion-item-kind-enum 13)
(defconst lsp/completion-item-kind-keyword 14)
(defconst lsp/completion-item-kind-snippet 15)
(defconst lsp/completion-item-kind-color 16)
(defconst lsp/completion-item-kind-file 17)
(defconst lsp/completion-item-kind-reference 18)
(defconst lsp/completion-item-kind-folder 19)
(defconst lsp/completion-item-kind-enum-member 20)
(defconst lsp/completion-item-kind-constant 21)
(defconst lsp/completion-item-kind-struct 22)
(defconst lsp/completion-item-kind-event 23)
(defconst lsp/completion-item-kind-operator 24)
(defconst lsp/completion-item-kind-type-parameter 25)
(defconst lsp/completion-trigger-kind-invoked 1)
(defconst lsp/completion-trigger-kind-trigger-character 2)
(defconst lsp/completion-trigger-kind-trigger-for-incomplete-completions 3)
(defconst lsp/diagnostic-severity-error 1)
(defconst lsp/diagnostic-severity-warning 2)
(defconst lsp/diagnostic-severity-information 3)
(defconst lsp/diagnostic-severity-hint 4)
(defconst lsp/diagnostic-tag-unnecessary 1)
(defconst lsp/diagnostic-tag-deprecated 2)
(defconst lsp/document-highlight-kind-text 1)
(defconst lsp/document-highlight-kind-read 2)
(defconst lsp/document-highlight-kind-write 3)
(defconst lsp/file-change-type-created 1)
(defconst lsp/file-change-type-changed 2)
(defconst lsp/file-change-type-deleted 3)
(defconst lsp/insert-text-format-plain-text 1)
(defconst lsp/insert-text-format-snippet 2)
(defconst lsp/message-type-error 1)
(defconst lsp/message-type-warning 2)
(defconst lsp/message-type-info 3)
(defconst lsp/message-type-log 4)
(defconst lsp/signature-help-trigger-kind-invoked 1)
(defconst lsp/signature-help-trigger-kind-trigger-character 2)
(defconst lsp/signature-help-trigger-kind-content-change 3)
(defconst lsp/symbol-kind-file 1)
(defconst lsp/symbol-kind-module 2)
(defconst lsp/symbol-kind-namespace 3)
(defconst lsp/symbol-kind-package 4)
(defconst lsp/symbol-kind-class 5)
(defconst lsp/symbol-kind-method 6)
(defconst lsp/symbol-kind-property 7)
(defconst lsp/symbol-kind-field 8)
(defconst lsp/symbol-kind-constructor 9)
(defconst lsp/symbol-kind-enum 10)
(defconst lsp/symbol-kind-interface 11)
(defconst lsp/symbol-kind-function 12)
(defconst lsp/symbol-kind-variable 13)
(defconst lsp/symbol-kind-constant 14)
(defconst lsp/symbol-kind-string 15)
(defconst lsp/symbol-kind-number 16)
(defconst lsp/symbol-kind-boolean 17)
(defconst lsp/symbol-kind-array 18)
(defconst lsp/symbol-kind-object 19)
(defconst lsp/symbol-kind-key 20)
(defconst lsp/symbol-kind-null 21)
(defconst lsp/symbol-kind-enum-member 22)
(defconst lsp/symbol-kind-struct 23)
(defconst lsp/symbol-kind-event 24)
(defconst lsp/symbol-kind-operator 25)
(defconst lsp/symbol-kind-type-parameter 26)
(defconst lsp/text-document-save-reason-manual 1)
(defconst lsp/text-document-save-reason-after-delay 2)
(defconst lsp/text-document-save-reason-focus-out 3)
(defconst lsp/text-document-sync-kind-none 1)
(defconst lsp/text-document-sync-kind-full 2)
(defconst lsp/text-document-sync-kind-incremental 3)
(defconst lsp/type-hierarchy-direction-children 1)
(defconst lsp/type-hierarchy-direction-parents 2)
(defconst lsp/type-hierarchy-direction-both 3)
(defconst lsp/call-hierarchy-direction-calls-from 1)
(defconst lsp/call-hierarchy-direction-calls-to 2)
(defconst lsp/response-error-code-parse-error 1)
(defconst lsp/response-error-code-invalid-request 2)
(defconst lsp/response-error-code-method-not-found 3)
(defconst lsp/response-error-code-invalid-params 4)
(defconst lsp/response-error-code-internal-error 5)
(defconst lsp/response-error-code-server-error-start 6)
(defconst lsp/response-error-code-server-error-end 7)

(lsp-interface
 (CallHierarchyCapabilities nil (:dynamicRegistration))
 (CallHierarchyItem (:kind :name :range :selectionRange :uri) (:detail :tags))
 (ClientCapabilities nil (:experimental :textDocument :workspace))
 (ClientInfo (:name) (:version))
 (CodeActionCapabilities nil (:codeActionLiteralSupport :dynamicRegistration :isPreferredSupport))
 (CodeActionContext (:diagnostics) (:only))
 (CodeActionKindCapabilities (:valueSet) nil)
 (CodeActionLiteralSupportCapabilities nil (:codeActionKind))
 (CodeActionOptions nil (:codeActionKinds))
 (CodeLensCapabilities nil (:dynamicRegistration))
 (CodeLensOptions (:resolveProvider) nil)
 (Color (:red :green :blue :alpha) nil)
 (ColorProviderCapabilities nil (:dynamicRegistration))
 (ColorProviderOptions nil (:documentSelector :id))
 (ColoringInformation (:range :styles) nil)
 (Command (:title :command) (:arguments))
 (CompletionCapabilities nil (:completionItem :completionItemKind :contextSupport :dynamicRegistration))
 (CompletionContext (:triggerKind) (:triggerCharacter))
 (CompletionItem (:label) (:additionalTextEdits :command :commitCharacters :data :deprecated :detail :documentation :filterText :insertText :insertTextFormat :kind :preselect :sortText :tags :textEdit :score))
 (CompletionItemCapabilities nil (:commitCharactersSupport :deprecatedSupport :documentationFormat :preselectSupport :snippetSupport :tagSupport))
 (CompletionItemKindCapabilities nil (:valueSet))
 (CompletionItemTagSupportCapabilities (:valueSet) nil)
 (CompletionOptions nil (:resolveProvider :triggerCharacters))
 (ConfigurationItem nil (:scopeUri :section))
 (CreateFileOptions nil (:ignoreIfExists :overwrite))
 (DeclarationCapabilities nil (:dynamicRegistration :linkSupport))
 (DefinitionCapabilities nil (:dynamicRegistration :linkSupport))
 (DeleteFileOptions nil (:ignoreIfNotExists :recursive))
 (Diagnostic (:range :message) (:code :relatedInformation :severity :source :tags))
 (DiagnosticRelatedInformation (:location :message) nil)
 (DiagnosticsTagSupport (:valueSet) nil)
 (DidChangeConfigurationCapabilities nil (:dynamicRegistration))
 (DidChangeWatchedFilesCapabilities nil (:dynamicRegistration))
 (DocumentFilter nil (:language :pattern :scheme))
 (DocumentHighlightCapabilities nil (:dynamicRegistration))
 (DocumentLinkCapabilities nil (:dynamicRegistration :tooltipSupport))
 (DocumentLinkOptions nil (:resolveProvider))
 (DocumentOnTypeFormattingOptions (:firstTriggerCharacter) (:moreTriggerCharacter))
 (DocumentSymbol (:kind :name :range :selectionRange) (:children :deprecated :detail))
 (DocumentSymbolCapabilities nil (:dynamicRegistration :hierarchicalDocumentSymbolSupport :symbolKind))
 (ExecuteCommandCapabilities nil (:dynamicRegistration))
 (ExecuteCommandOptions (:commands) nil)
 (FileEvent (:type :uri) nil)
 (FileSystemWatcher (:globPattern) (:kind))
 (FoldingRangeCapabilities nil (:dynamicRegistration :lineFoldingOnly :rangeLimit))
 (FoldingRangeProviderOptions nil (:documentSelector :id))
 (FormattingCapabilities nil (:dynamicRegistration))
 (FormattingOptions (:loadFactor :threshold :accessOrder) nil)
 (HoverCapabilities nil (:contentFormat :dynamicRegistration))
 (ImplementationCapabilities nil (:dynamicRegistration :linkSupport))
 (Location (:range :uri) nil)
 (MarkedString (:language :value) nil)
 (MarkupContent (:kind :value) nil)
 (MessageActionItem (:title) nil)
 (OnTypeFormattingCapabilities nil (:dynamicRegistration))
 (ParameterInformation (:label) (:documentation))
 (ParameterInformationCapabilities nil (:labelOffsetSupport))
 (Position (:character :line) nil)
 (PublishDiagnosticsCapabilities nil (:relatedInformation :tagSupport :versionSupport))
 (Range (:start :end) nil)
 (RangeFormattingCapabilities nil (:dynamicRegistration))
 (ReferenceContext (:includeDeclaration) nil)
 (ReferencesCapabilities nil (:dynamicRegistration))
 (Registration (:method :id) (:registerOptions))
 (RenameCapabilities nil (:dynamicRegistration :prepareSupport))
 (RenameFileOptions nil (:ignoreIfExists :overwrite))
 (RenameOptions nil (:documentSelector :id :prepareProvider))
 (ResourceChange nil (:current :newUri))
 (ResourceOperation (:kind) nil)
 (SaveOptions nil (:includeText))
 (SelectionRange (:range) (:parent))
 (SelectionRangeCapabilities nil (:dynamicRegistration))
 (SemanticHighlightingCapabilities nil (:semanticHighlighting))
 (SemanticHighlightingInformation (:line) (:tokens))
 (SemanticHighlightingServerCapabilities nil (:scopes))
 (ServerCapabilities nil (:callHierarchyProvider :codeActionProvider :codeLensProvider :colorProvider :completionProvider :declarationProvider :definitionProvider :documentFormattingProvider :documentHighlightProvider :documentLinkProvider :documentOnTypeFormattingProvider :documentRangeFormattingProvider :documentSymbolProvider :executeCommandProvider :experimental :foldingRangeProvider :hoverProvider :implementationProvider :referencesProvider :renameProvider :selectionRangeProvider :semanticHighlighting :signatureHelpProvider :textDocumentSync :typeDefinitionProvider :typeHierarchyProvider :workspace :workspaceSymbolProvider :semanticTokensProvider))
 (ServerInfo (:name) (:version))
 (SignatureHelp (:signatures) (:activeParameter :activeSignature))
 (SignatureHelpCapabilities nil (:contextSupport :dynamicRegistration :signatureInformation))
 (SignatureHelpContext (:triggerKind :isRetrigger) (:activeSignatureHelp :triggerCharacter))
 (SignatureHelpOptions nil (:retriggerCharacters :triggerCharacters))
 (SignatureInformation (:label) (:documentation :parameters))
 (SignatureInformationCapabilities nil (:documentationFormat :parameterInformation))
 (StaticRegistrationOptions nil (:documentSelector :id))
 (SymbolCapabilities nil (:dynamicRegistration :symbolKind))
 (SymbolKindCapabilities nil (:valueSet))
 (SynchronizationCapabilities nil (:didSave :dynamicRegistration :willSave :willSaveWaitUntil))
 (TextDocumentClientCapabilities nil (:callHierarchy :codeAction :codeLens :colorProvider :completion :declaration :definition :documentHighlight :documentLink :documentSymbol :foldingRange :formatting :hover :implementation :onTypeFormatting :publishDiagnostics :rangeFormatting :references :rename :selectionRange :semanticHighlightingCapabilities :signatureHelp :synchronization :typeDefinition :typeHierarchyCapabilities))
 (TextDocumentContentChangeEvent (:text) (:range :rangeLength))
 (TextDocumentEdit (:textDocument :edits) nil)
 (TextDocumentIdentifier (:uri) nil)
 (TextDocumentItem (:languageId :text :uri :version) nil)
 (TextDocumentSyncOptions nil (:change :openClose :save :willSave :willSaveWaitUntil))
 (TextEdit (:newText :range) nil)
 (TypeDefinitionCapabilities nil (:dynamicRegistration :linkSupport))
 (TypeHierarchyCapabilities nil (:dynamicRegistration))
 (TypeHierarchyItem (:kind :name :range :selectionRange :uri) (:children :data :deprecated :detail :parents))
 (Unregistration (:method :id) nil)
 (VersionedTextDocumentIdentifier (:uri) (:version))
 (WorkspaceClientCapabilities nil (:applyEdit :configuration :didChangeConfiguration :didChangeWatchedFiles :executeCommand :symbol :workspaceEdit :workspaceFolders))
 (WorkspaceEdit nil (:changes :documentChanges :resourceChanges))
 (WorkspaceEditCapabilities nil (:documentChanges :failureHandling :resourceChanges :resourceOperations))
 (WorkspaceFolder (:uri) (:name))
 (WorkspaceFoldersChangeEvent (:removed :added) nil)
 (WorkspaceFoldersOptions nil (:changeNotifications :supported))
 (WorkspaceServerCapabilities nil (:workspaceFolders))
 (ApplyWorkspaceEditParams (:edit) (:label))
 (ApplyWorkspaceEditResponse (:applied) nil)
 (CallHierarchyIncomingCall (:from :fromRanges) nil)
 (CallHierarchyIncomingCallsParams (:item) nil)
 (CallHierarchyOutgoingCall (:to :fromRanges) nil)
 (CallHierarchyOutgoingCallsParams (:item) nil)
 (CallHierarchyPrepareParams (:textDocument :position) (:uri))
 (CodeAction (:title) (:command :diagnostics :edit :isPreferred :kind))
 (CodeActionKind nil nil)
 (CodeActionParams (:textDocument :context :range) nil)
 (CodeLens (:range) (:command :data))
 (CodeLensParams (:textDocument) nil)
 (CodeLensRegistrationOptions nil (:documentSelector :resolveProvider))
 (ColorInformation (:color :range) nil)
 (ColorPresentation (:label) (:additionalTextEdits :textEdit))
 (ColorPresentationParams (:color :textDocument :range) nil)
 (ColoringParams (:uri :infos) nil)
 (ColoringStyle nil nil)
 (CompletionList (:items :isIncomplete) nil)
 (CompletionParams (:textDocument :position) (:context :uri))
 (CompletionRegistrationOptions nil (:documentSelector :resolveProvider :triggerCharacters))
 (ConfigurationParams (:items) nil)
 (CreateFile (:kind :uri) (:options))
 (DeclarationParams (:textDocument :position) (:uri))
 (DefinitionParams (:textDocument :position) (:uri))
 (DeleteFile (:kind :uri) (:options))
 (DidChangeConfigurationParams (:settings) nil)
 (DidChangeTextDocumentParams (:contentChanges :textDocument) (:uri))
 (DidChangeWatchedFilesParams (:changes) nil)
 (DidChangeWatchedFilesRegistrationOptions (:watchers) nil)
 (DidChangeWorkspaceFoldersParams (:event) nil)
 (DidCloseTextDocumentParams (:textDocument) nil)
 (DidOpenTextDocumentParams (:textDocument) (:text))
 (DidSaveTextDocumentParams (:textDocument) (:text))
 (DocumentColorParams (:textDocument) nil)
 (DocumentFormattingParams (:textDocument :options) nil)
 (DocumentHighlight (:range) (:kind))
 (DocumentHighlightParams (:textDocument :position) (:uri))
 (DocumentLink (:range) (:data :target :tooltip))
 (DocumentLinkParams (:textDocument) nil)
 (DocumentLinkRegistrationOptions nil (:documentSelector :resolveProvider))
 (DocumentOnTypeFormattingParams (:ch :textDocument :options :position) nil)
 (DocumentOnTypeFormattingRegistrationOptions (:firstTriggerCharacter) (:documentSelector :moreTriggerCharacter))
 (DocumentRangeFormattingParams (:textDocument :options :range) nil)
 (DocumentSymbolParams (:textDocument) nil)
 (DynamicRegistrationCapabilities nil (:dynamicRegistration))
 (ExecuteCommandParams (:command) (:arguments))
 (ExecuteCommandRegistrationOptions (:commands) nil)
 (FailureHandlingKind nil nil)
 (FoldingRange (:endLine :startLine) (:endCharacter :kind :startCharacter))
 (FoldingRangeKind nil nil)
 (FoldingRangeRequestParams (:textDocument) nil)
 (Hover (:contents) (:range))
 (HoverParams (:textDocument :position) (:uri))
 (ImplementationParams (:textDocument :position) (:uri))
 (InitializeError (:retry) nil)
 (InitializeErrorCode nil nil)
 (InitializeParams nil (:capabilities :clientInfo :clientName :initializationOptions :processId :rootPath :rootUri :trace :workspaceFolders))
 (InitializeResult (:capabilities) (:serverInfo))
 (InitializedParams nil nil)
 (LocationLink (:targetSelectionRange :targetUri :targetRange) (:originSelectionRange))
 (MarkupKind nil nil)
 (MessageParams (:type :message) nil)
 (PrepareRenameParams (:textDocument :position) (:uri))
 (PrepareRenameResult (:range :placeholder) nil)
 (PublishDiagnosticsParams (:diagnostics :uri) (:version))
 (ReferenceParams (:textDocument :context :position) (:uri))
 (RegistrationParams (:registrations) nil)
 (RenameFile (:kind :newUri :oldUri) (:options))
 (RenameParams (:newName :textDocument :position) (:uri))
 (ResolveTypeHierarchyItemParams (:item :resolve :direction) nil)
 (ResourceOperationKind nil nil)
 (SelectionRangeParams (:textDocument :positions) nil)
 (SemanticHighlightingParams (:textDocument :lines) nil)
 (ShowMessageRequestParams (:type :message) (:actions))
 (SignatureHelpParams (:textDocument :position) (:context :uri))
 (SignatureHelpRegistrationOptions nil (:documentSelector :triggerCharacters))
 (SymbolInformation (:kind :name :location) (:containerName :deprecated))
 (TextDocumentChangeRegistrationOptions (:syncKind) (:documentSelector))
 (TextDocumentPositionParams (:textDocument :position) (:uri))
 (TextDocumentRegistrationOptions nil (:documentSelector))
 (TextDocumentSaveRegistrationOptions nil (:documentSelector :includeText))
 (TypeDefinitionParams (:textDocument :position) (:uri))
 (TypeHierarchyParams (:resolve :textDocument :position) (:direction :uri))
 (UnregistrationParams (:unregisterations) nil)
 (WatchKind nil nil)
 (WillSaveTextDocumentParams (:reason :textDocument) nil)
 (WorkspaceSymbolParams (:query) nil))


(provide 'lsp-protocol)

;;; lsp-protocol.el ends here
