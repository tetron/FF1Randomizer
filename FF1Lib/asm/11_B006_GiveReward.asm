
BANK_TALKROUTINE	= $11
ret_bank        = $58

;; Bank 11 $B006
;; New jump point for NPC-only items:
;; IN:
;;       'A' should be set to the item ID, 224-255 are special values for variables
;; Result:
;;       'C' set if can't carry any more, otherwise clear
;;       'X' Dialog ID
;;       'A' Also Dialog ID
GiveReward:                    ; (8 bytes)
    LDY #BANK_TALKROUTINE      ; Get return bank AC 11 00
    STY ret_bank               ; for LoadPrice 8C 58 00
    STA dlg_itemid             ; record that as the item id so it can be printed in the dialogue box 8561
    ADC #$20                   ; Add 0x20 to account for the 'items' offset 6920
    CMP #$3C                   ; see if the ID is >= item_stop C93C
    BCS @NotItem               ; B028
  @Item:                       ; (5 + 15 + 7 bytes)
    TAX                        ; put item ID in X AA
    CMP #$0C                   ; then check for canal C90C
    BNE :+                     ; If canal then D005
      DEC unsram, X            ; decrement DE0060
      BCS @WasCanal            ; and open it B018
:   CMP #$36                   ; CMP ItemId with Tent C936
    BCC :+                     ; < Tent normal Add One routine 9011
		SBC #$36               ; Subtract TentOffset E936
		TAY                    ; Punt Index into Y A8
        LDA unsram, X          ; load inventory count BD0060
        CMP #$63               ; Compare with 99 C963
        BCS @TooFull           ; don't pick it up if consumable >= 99 B03D
        ADC lut_ConsStack, Y   ; add ConsumableStackSize (actual StackSize minus 1)	 7900B0	
        STA unsram, X          ; MadMartin: store into inventory 9D0060
		TXA					   ; Restore ItemId into A 8A
:	INC unsram, X              ; otherwise give them one of this item FE0060
@WasCanal:
    CMP #$31                   ; if >= item_canoe (shard) then play regular jingle C931
    BCS @ClearChest            ; B02A
    BCC @OpenChest             ; 902B
  @NotItem:                    ; (6 + 9 + 4 + 9 + 7 + 5 = 40 bytes)
    LDA dlg_itemid             ; restore item id A561
    CMP #$6C                   ; check if gold C96C
    BCC :+                     ; Continue if gold 9009
     JSR LoadPrice             ; get the price of the item (the amount of gold in the chest) 20B9EC
     JSR AddGPToParty          ; add that price to the party's GP 20EADD
     JMP @ClearChest           ; then mark the chest as open, and exit 4C63B0
:   CMP #$44                   ; >= 68 means it's armor C944
    BCS :+                     ; B009
      JSR FindEmptyWeaponSlot  ; Find an available slot to place this weapon in 2034DD
      BCS @TooFull             ; if there are no available slots, jump to 'Too Full' message B007
      LDA #$E5                 ; convert to index where 1 is first weapon A9E5
      BCC @EquipmentGet        ; 9007
    JSR FindEmptyArmorSlot     ; Find an empty slot to put this armor 2046DD
    BCS @TooFull               ;  if there are no available slots, jump to 'Too Full' message B00C
    LDA #$BD                   ; convert to index where 1 is first weapon/armor A9BD
  @EquipmentGet:               ; 'A' should hold the equipment ID and 'X' the item slot
    ADC dlg_itemid             ; 6561
    STA ch_stats, X            ; add it to the previously found empty slot 9D0061
  @ClearChest:                 ; Cleanup, set jingle and dialog id (12 bytes)
    CLC                        ; 18
  @OpenRegularChest:           ;  then continue on to mark the chest as open
    INC dlgsfx                 ; set dlgsfx to play the TC jingle E67D
  @OpenChest:                  ;
    INC dlgsfx                 ; set dlgsfx to play the TC jingle E67D
  @TooFull:                    ; jump here with C set to show "Can't Hold" text and no jingle
    LDX #DLGID_TCGET           ; and select "In This chest you found..." text A2F0
    BCC :+                     ; 9004
      INC $60B9                ; EEB760
      INX                      ; E8
:   TXA                        ; 8A
    RTS                        ; 60
