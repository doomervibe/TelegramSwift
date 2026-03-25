//
//  SystemQueue.swift
//  Telegram-Mac
//
//  Created by keepcoder on 08/09/16.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Cocoa
import SwiftSignalKit
import TelegramCore

import TGUIKit
import Postbox
import CoreMediaIO
import Localization

public let resourcesQueue = Queue(name: "ResourcesQueue", qos: .utility)
public let prepareQueue = Queue(name: "PrepareQueue", qos: .utility)
public let messagesViewQueue = Queue(name: "messagesViewQueue", qos: .utility)

public let appName = "Telegram"
public let kMediaImageExt = "jpg";
public let kMediaGifExt = "mov";
public let kMediaVideoExt = "mp4";



var systemAppearance: NSAppearance {
    if #available(OSX 10.14, *) {
        return NSApp.effectiveAppearance
    } else {
        return NSAppearance.current
    }
}


public func deliverOnPrepareQueue<T, E>(_ signal: Signal<T, E>) -> Signal<T, E> {
    return signal |> deliverOn(prepareQueue)
}
public func deliverOnMessagesViewQueue<T, E>(_ signal: Signal<T, E>) -> Signal<T, E> {
    return signal |> deliverOn(messagesViewQueue)
}

public func deliverOnResourceQueue<T, E>(_ signal: Signal<T, E>) -> Signal<T, E> {
    return signal |> deliverOn(resourcesQueue)
}


func proccessEntriesWithoutReverse<T,R>(_ left:[R]?,right:[R],_ convertEntry:@escaping (R) -> T) -> ([Int],[(Int,T)],[(Int,T)]) where R:Comparable, R:Identifiable {
    return proccessEntries(false, left, right: right, convertEntry)
}

func proccessEntries<T,R>(_ left:[R]?,right:[R],_ convertEntry:@escaping (R) -> T) -> ([Int],[(Int,T)],[(Int,T)]) where R:Comparable, R:Identifiable {
    return proccessEntries(true, left, right: right, convertEntry)
}

fileprivate func proccessEntries<T,R>(_ reverse:Bool = true, _ left:[R]?,right:[R],_ convertEntry:@escaping (R) -> T) -> ([Int],[(Int,T)],[(Int,T)]) where R:Comparable, R:Identifiable {
    if let left = left  {
        
        let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: left, rightList: right)
        
        var insertedItems:[(Int,T)] = []
        var updatedItems:[(Int,T)] = []
        
        var newItems:[R.T:T] = [:]
        
        for (idx, entry, _) in indicesAndItems {
            let item:T = newItems[entry.stableId] ?? convertEntry(entry)
            newItems[entry.stableId] = item
            insertedItems.append((idx,item))
        }
        
        for (idx, entry, _) in updateIndices {
            let item:T = newItems[entry.stableId] ?? convertEntry(entry)
            newItems[entry.stableId] = item
            updatedItems.append((idx,item))
        }
        
        
        let removed = reverse ? reverseIndexList(deleteIndices, left.count) : deleteIndices
        let inserted = reverse ? reverseIndexList(insertedItems, left.count, right.count) : insertedItems
        let updated = reverse ? reverseIndexList(updatedItems, left.count, right.count) : updatedItems
        
        if !(removed.count > 0 || inserted.count > 0 || updated.count > 0) {
            assert(left == right)
        }
        
        return (removed,inserted,updated)
    } else {
        
        var list:[(Int,T)] = []
        
        for entry in (reverse ? right.reversed() : right) {
            list.append((list.count,convertEntry(entry)))
        }
        
        return ([],list,[])
        
    }
}




func DALDevices() -> [AVCaptureDevice] {
    let video = AVCaptureDevice.devices(for: .video)
    let muxed:[AVCaptureDevice] = AVCaptureDevice.devices(for: .muxed) //[]//
    // && $0.hasMediaType(.video)
    
    
    return (video + muxed).filter { $0.isConnected && !$0.isSuspended }
}

func shouldBeMirrored(_ device: AVCaptureDevice) -> Bool {
    
    if !device.hasMediaType(.video) {
        return false
    }
    
    var latency_pa = CMIOObjectPropertyAddress(
               mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyLatency),
               mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
               mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
           )
    var dataSize = UInt32(0)
    
    let id = device.value(forKey: "_connectionID") as? CMIOObjectID

    if let id = id {
        if CMIOObjectGetPropertyDataSize(id, &latency_pa, 0, nil, &dataSize) == OSStatus(kCMIOHardwareNoError) {
            return false
        } else {
           return true
        }
    }
    return true
}



func strings() -> L10n.Type {
    return L10n.self
}

enum FocusStrings {
    private enum SupportedLanguage {
        case en
        case de
        case es
        case it
        case nl
        case ptBR
        case ru
        case uk
    }
    
    private struct Catalog {
        let inbox: String
        let channels: String
        let archive: String
        let saved: String
        let savedMessages: String
        let contacts: String
        let search: String
        let stories: String
        let settings: String
        let conversations: String
        let notes: String
        let digest: String
        let tapToOpen: String
        let channelsWithNewPosts: String
        let writeAReply: String
        let voiceMessage: String
        let unknown: String
        let link: String
        let applyForFocusFilter: String
        let focusFilterEmojiInfo: String
    }
    
    private static var language: SupportedLanguage {
        let code = appCurrentLanguage.baseLanguageCode
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: "-raw", with: "")
        
        switch code {
        case "de":
            return .de
        case "es":
            return .es
        case "it":
            return .it
        case "nl":
            return .nl
        case "pt-br", "pt":
            return .ptBR
        case "ru":
            return .ru
        case "uk":
            return .uk
        default:
            return .en
        }
    }
    
    private static var catalog: Catalog {
        switch language {
        case .en:
            return Catalog(
                inbox: "Inbox",
                channels: "Channels",
                archive: "Archive",
                saved: "Saved",
                savedMessages: "Saved Messages",
                contacts: "Contacts",
                search: "Search",
                stories: "Stories",
                settings: "Settings",
                conversations: "Conversations",
                notes: "Notes",
                digest: "Digest",
                tapToOpen: "Tap to open",
                channelsWithNewPosts: "Channels with new posts",
                writeAReply: "Write a reply…",
                voiceMessage: "Voice message",
                unknown: "Unknown",
                link: "Link",
                applyForFocusFilter: "Apply for Focus Filter",
                focusFilterEmojiInfo: "This emoji will be used for system Focus Mode"
            )
        case .de:
            return Catalog(
                inbox: "Posteingang",
                channels: "Kanäle",
                archive: "Archiv",
                saved: "Gespeichert",
                savedMessages: "Gespeicherte Nachrichten",
                contacts: "Kontakte",
                search: "Suche",
                stories: "Stories",
                settings: "Einstellungen",
                conversations: "Unterhaltungen",
                notes: "Notizen",
                digest: "Digest",
                tapToOpen: "Tippen zum Öffnen",
                channelsWithNewPosts: "Kanäle mit neuen Beiträgen",
                writeAReply: "Antwort schreiben…",
                voiceMessage: "Sprachnachricht",
                unknown: "Unbekannt",
                link: "Link",
                applyForFocusFilter: "Auf Focus-Filter anwenden",
                focusFilterEmojiInfo: "Dieses Emoji wird für den systemweiten Fokusmodus verwendet"
            )
        case .es:
            return Catalog(
                inbox: "Bandeja de entrada",
                channels: "Canales",
                archive: "Archivo",
                saved: "Guardado",
                savedMessages: "Mensajes guardados",
                contacts: "Contactos",
                search: "Buscar",
                stories: "Historias",
                settings: "Configuración",
                conversations: "Conversaciones",
                notes: "Notas",
                digest: "Resumen",
                tapToOpen: "Toca para abrir",
                channelsWithNewPosts: "Canales con publicaciones nuevas",
                writeAReply: "Escribe una respuesta…",
                voiceMessage: "Mensaje de voz",
                unknown: "Desconocido",
                link: "Enlace",
                applyForFocusFilter: "Aplicar al filtro Focus",
                focusFilterEmojiInfo: "Este emoji se usará para el modo Focus del sistema"
            )
        case .it:
            return Catalog(
                inbox: "Posta in arrivo",
                channels: "Canali",
                archive: "Archivio",
                saved: "Salvati",
                savedMessages: "Messaggi salvati",
                contacts: "Contatti",
                search: "Cerca",
                stories: "Storie",
                settings: "Impostazioni",
                conversations: "Conversazioni",
                notes: "Note",
                digest: "Riepilogo",
                tapToOpen: "Tocca per aprire",
                channelsWithNewPosts: "Canali con nuovi post",
                writeAReply: "Scrivi una risposta…",
                voiceMessage: "Messaggio vocale",
                unknown: "Sconosciuto",
                link: "Link",
                applyForFocusFilter: "Applica al filtro Focus",
                focusFilterEmojiInfo: "Questa emoji verrà usata per la modalità Focus di sistema"
            )
        case .nl:
            return Catalog(
                inbox: "Postvak IN",
                channels: "Kanalen",
                archive: "Archief",
                saved: "Opgeslagen",
                savedMessages: "Opgeslagen berichten",
                contacts: "Contacten",
                search: "Zoeken",
                stories: "Verhalen",
                settings: "Instellingen",
                conversations: "Gesprekken",
                notes: "Notities",
                digest: "Overzicht",
                tapToOpen: "Tik om te openen",
                channelsWithNewPosts: "Kanalen met nieuwe berichten",
                writeAReply: "Schrijf een antwoord…",
                voiceMessage: "Spraakbericht",
                unknown: "Onbekend",
                link: "Link",
                applyForFocusFilter: "Toepassen op Focus-filter",
                focusFilterEmojiInfo: "Deze emoji wordt gebruikt voor de Focus-modus van het systeem"
            )
        case .ptBR:
            return Catalog(
                inbox: "Caixa de entrada",
                channels: "Canais",
                archive: "Arquivo",
                saved: "Salvos",
                savedMessages: "Mensagens salvas",
                contacts: "Contatos",
                search: "Buscar",
                stories: "Histórias",
                settings: "Configurações",
                conversations: "Conversas",
                notes: "Notas",
                digest: "Resumo",
                tapToOpen: "Toque para abrir",
                channelsWithNewPosts: "Canais com novas publicações",
                writeAReply: "Escreva uma resposta…",
                voiceMessage: "Mensagem de voz",
                unknown: "Desconhecido",
                link: "Link",
                applyForFocusFilter: "Aplicar ao filtro Focus",
                focusFilterEmojiInfo: "Este emoji será usado para o modo Focus do sistema"
            )
        case .ru:
            return Catalog(
                inbox: "Входящие",
                channels: "Каналы",
                archive: "Архив",
                saved: "Избранное",
                savedMessages: "Сохранённые сообщения",
                contacts: "Контакты",
                search: "Поиск",
                stories: "Истории",
                settings: "Настройки",
                conversations: "Диалоги",
                notes: "Заметки",
                digest: "Дайджест",
                tapToOpen: "Нажмите, чтобы открыть",
                channelsWithNewPosts: "Каналы с новыми публикациями",
                writeAReply: "Напишите ответ…",
                voiceMessage: "Голосовое сообщение",
                unknown: "Неизвестно",
                link: "Ссылка",
                applyForFocusFilter: "Применить к фильтру Focus",
                focusFilterEmojiInfo: "Этот эмодзи будет использоваться для системного режима Focus"
            )
        case .uk:
            return Catalog(
                inbox: "Вхідні",
                channels: "Канали",
                archive: "Архів",
                saved: "Збережене",
                savedMessages: "Збережені повідомлення",
                contacts: "Контакти",
                search: "Пошук",
                stories: "Історії",
                settings: "Налаштування",
                conversations: "Розмови",
                notes: "Нотатки",
                digest: "Дайджест",
                tapToOpen: "Натисніть, щоб відкрити",
                channelsWithNewPosts: "Канали з новими дописами",
                writeAReply: "Напишіть відповідь…",
                voiceMessage: "Голосове повідомлення",
                unknown: "Невідомо",
                link: "Посилання",
                applyForFocusFilter: "Застосувати до фільтра Focus",
                focusFilterEmojiInfo: "Цей емодзі використовуватиметься для системного режиму Focus"
            )
        }
    }
    
    static var inbox: String { catalog.inbox }
    static var channels: String { catalog.channels }
    static var archive: String { catalog.archive }
    static var saved: String { catalog.saved }
    static var savedMessages: String { catalog.savedMessages }
    static var contacts: String { catalog.contacts }
    static var search: String { catalog.search }
    static var stories: String { catalog.stories }
    static var settings: String { catalog.settings }
    static var conversations: String { catalog.conversations }
    static var notes: String { catalog.notes }
    static var digest: String { catalog.digest }
    static var tapToOpen: String { catalog.tapToOpen }
    static var channelsWithNewPosts: String { catalog.channelsWithNewPosts }
    static var writeAReply: String { catalog.writeAReply }
    static var voiceMessage: String { catalog.voiceMessage }
    static var unknown: String { catalog.unknown }
    static var link: String { catalog.link }
    static var applyForFocusFilter: String { catalog.applyForFocusFilter }
    static var focusFilterEmojiInfo: String { catalog.focusFilterEmojiInfo }
    
    static func digestChannelCount(_ count: Int) -> String {
        switch language {
        case .de:
            return "\(count) " + (count == 1 ? "Kanal" : "Kanäle")
        case .es:
            return "\(count) " + (count == 1 ? "canal" : "canales")
        case .it:
            return "\(count) " + (count == 1 ? "canale" : "canali")
        case .nl:
            return "\(count) " + (count == 1 ? "kanaal" : "kanalen")
        case .ptBR:
            return "\(count) " + (count == 1 ? "canal" : "canais")
        case .ru:
            return "\(count) \(slavicPlural(count, one: "канал", few: "канала", many: "каналов"))"
        case .uk:
            return "\(count) \(slavicPlural(count, one: "канал", few: "канали", many: "каналів"))"
        case .en:
            return "\(count) " + (count == 1 ? "channel" : "channels")
        }
    }
    
    private static func slavicPlural(_ count: Int, one: String, few: String, many: String) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod10 == 1 && mod100 != 11 {
            return one
        } else if (2 ... 4).contains(mod10) && !(12 ... 14).contains(mod100) {
            return few
        } else {
            return many
        }
    }
}
