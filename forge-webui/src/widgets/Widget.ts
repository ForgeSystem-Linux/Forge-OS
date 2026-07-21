/**
 * Forge DE - Widget Base Class
 */

export abstract class Widget {
  protected element: HTMLElement;
  protected children: Widget[] = [];

  constructor(tag: string = "div") {
    this.element = document.createElement(tag);
  }

  abstract render(): HTMLElement;

  mount(parent: HTMLElement): void {
    parent.appendChild(this.render());
  }

  unmount(): void {
    this.element.remove();
  }

  addChild(child: Widget): void {
    this.children.push(child);
  }

  removeChild(child: Widget): void {
    const index = this.children.indexOf(child);
    if (index > -1) {
      this.children.splice(index, 1);
    }
  }
}
