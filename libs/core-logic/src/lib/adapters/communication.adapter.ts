import { Observable } from 'rxjs';

/**
 * Абстрактный адаптер для связи с физическим устройством.
 * Определяет контракт, которому должны следовать платформенные реализации.
 * Ядро системы зависит ТОЛЬКО от этой абстракции.
 */
export abstract class CommunicationAdapter {
  /**
   * Состояние подключения к устройству.
   * true - подключено, false - не подключено.
   */
  abstract readonly connectionState$: Observable<boolean>;

  /**
   * Инициирует подключение к устройству по его имени или ID.
   * @param deviceIdentifier Имя или уникальный идентификатор устройства.
   * @returns Observable<boolean> - поток, который вернет true в случае успеха.
   */
  abstract connect(deviceIdentifier: string): Observable<boolean>;


  abstract disconnect(): void;
  
  abstract writeData(data: string): void;
}